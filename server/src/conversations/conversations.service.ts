import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { AccountsService } from '../accounts/accounts.service';
import { AttachmentsService } from '../attachments/attachments.service';
import { Store, StoreFactory } from '../common/store';
import { EditMessageDto, SendMessageDto, UploadAttachmentDto } from './conversations.dto';
import { ConversationEntity, MessageEntity } from './conversation.types';

export const REQUEST_PREFIX = 'Hizmet Talebi: ';

export interface OpenConversationInput {
  requestId: string;
  customerId: string;
  customerName: string;
  providerId: string;
  providerName: string;
  subject: string;
  description: string;
}

/** Chat between one customer and one usta. Every message is stored (see KVKK / dispute handling text). */
@Injectable()
export class ConversationsService {
  private readonly conversations: Store<ConversationEntity>;
  private readonly messages: Store<MessageEntity>;

  constructor(
    stores: StoreFactory,
    private readonly accounts: AccountsService,
    private readonly attachments: AttachmentsService,
  ) {
    this.conversations = stores.collection<ConversationEntity>('conversations');
    this.messages = stores.collection<MessageEntity>('messages');
  }

  /** Opens the chat for a new service request; its first message is always "Hizmet Talebi: …". */
  async openForRequest(input: OpenConversationInput): Promise<ConversationEntity> {
    const now = new Date().toISOString();
    const text = `${REQUEST_PREFIX}${input.description.trim()}`;
    const providerAccount = await this.accounts.findByProviderId(input.providerId);
    const conversation = await this.conversations.insert({
      requestId: input.requestId,
      customerId: input.customerId,
      customerName: input.customerName,
      providerId: input.providerId,
      providerName: input.providerName,
      providerAccountId: providerAccount?.id ?? null,
      subject: input.subject,
      createdAt: now,
      lastMessageAt: now,
      lastMessageText: text,
      unreadCustomer: 0,
      unreadProvider: 1,
    });
    await this.messages.insert({
      conversationId: conversation.id,
      senderId: input.customerId,
      senderRole: 'customer',
      kind: 'request',
      text,
      attachmentId: null,
      replyToId: null,
      createdAt: now,
      editedAt: null,
      deletedAt: null,
    });
    return conversation;
  }

  /** A neutral line in the chat, e.g. "Usta talebi kabul etti." */
  async systemMessage(requestId: string, text: string): Promise<void> {
    const conversation = (await this.conversations.find({ requestId }, { limit: 1 }))[0];
    if (!conversation) return;
    const now = new Date().toISOString();
    await this.messages.insert({
      conversationId: conversation.id,
      senderId: 'system',
      senderRole: 'system',
      kind: 'system',
      text,
      attachmentId: null,
      replyToId: null,
      createdAt: now,
      editedAt: null,
      deletedAt: null,
    });
    await this.conversations.update(conversation.id, { lastMessageAt: now, lastMessageText: text });
  }

  /** Right to erasure: the name goes, the conversation stays (dispute handling, see privacy text). */
  async anonymizeCustomer(customerId: string): Promise<void> {
    for (const c of await this.conversations.find({ customerId })) {
      await this.conversations.update(c.id, { customerName: 'Silinmiş kullanıcı' });
    }
  }

  async byRequestIds(requestIds: string[]): Promise<Map<string, ConversationEntity>> {
    if (!requestIds.length) return new Map();
    const rows = await this.conversations.find({ requestId: { $in: requestIds } });
    return new Map(rows.map((c) => [c.requestId, c]));
  }

  async forCustomer(customerId: string) {
    return this.conversations.find({ customerId }, { sort: { lastMessageAt: -1 } });
  }

  async forProvider(providerId: string) {
    return this.conversations.find({ providerId }, { sort: { lastMessageAt: -1 } });
  }

  /** The usta's side can answer only when the usta has an app account. */
  async view(id: string, viewerId: string) {
    const conversation = await this.require(id);
    const role = await this.roleOf(conversation, viewerId);
    if (!role) throw new ForbiddenException('Bu sohbete erişimin yok.');
    const providerAccount = conversation.providerAccountId
      ? conversation.providerAccountId
      : (await this.accounts.findByProviderId(conversation.providerId))?.id ?? null;
    return { ...conversation, providerAccountId: providerAccount, viewerRole: role, providerOnApp: providerAccount != null };
  }

  /** All messages, or only what changed after [after] (new, edited or deleted) for cheap polling. */
  async list(id: string, viewerId: string, after?: string): Promise<MessageEntity[]> {
    await this.view(id, viewerId);
    const rows = await this.messages.find({ conversationId: id }, { sort: { createdAt: 1 } });
    const visible = rows.map((m) => (m.deletedAt ? { ...m, text: '', attachmentId: null } : m));
    if (!after) return visible;
    return visible.filter((m) => m.createdAt > after || (m.editedAt ?? '') > after || (m.deletedAt ?? '') > after);
  }

  async send(id: string, dto: SendMessageDto): Promise<MessageEntity> {
    const conversation = await this.require(id);
    const role = await this.roleOf(conversation, dto.senderId);
    if (!role) throw new ForbiddenException('Bu sohbete mesaj gönderemezsin.');
    const text = (dto.text ?? '').trim();
    if (!text && !dto.attachmentId) throw new BadRequestException('Mesaj boş olamaz.');
    if (dto.attachmentId) {
      const a = await this.attachments.get(dto.attachmentId);
      if (!a || a.conversationId !== id) throw new BadRequestException('Fotoğraf bulunamadı.');
    }
    if (dto.replyToId) {
      const r = await this.messages.get(dto.replyToId);
      if (!r || r.conversationId !== id) throw new BadRequestException('Yanıtlanan mesaj bulunamadı.');
    }
    const now = new Date().toISOString();
    const message = await this.messages.insert({
      conversationId: id,
      senderId: dto.senderId,
      senderRole: role,
      kind: dto.attachmentId ? 'image' : 'text',
      text,
      attachmentId: dto.attachmentId ?? null,
      replyToId: dto.replyToId ?? null,
      createdAt: now,
      editedAt: null,
      deletedAt: null,
    });
    await this.conversations.update(id, {
      lastMessageAt: now,
      lastMessageText: text || 'Fotoğraf',
      ...(role === 'customer'
        ? { unreadProvider: conversation.unreadProvider + 1 }
        : { unreadCustomer: conversation.unreadCustomer + 1 }),
    });
    return message;
  }

  async edit(messageId: string, dto: EditMessageDto): Promise<MessageEntity> {
    const message = await this.ownMessage(messageId, dto.senderId);
    if (message.kind !== 'text') throw new BadRequestException('Bu mesaj düzenlenemez.');
    const updated = await this.messages.update(messageId, { text: dto.text.trim(), editedAt: new Date().toISOString() });
    return updated!;
  }

  /** Soft delete: the bubble stays as "Mesaj silindi" so replies keep their context. */
  async remove(messageId: string, senderId: string): Promise<MessageEntity> {
    const message = await this.ownMessage(messageId, senderId);
    if (message.kind === 'request') throw new BadRequestException('Hizmet talebi mesajı silinemez; talebi iptal edebilirsin.');
    return (await this.messages.update(messageId, { deletedAt: new Date().toISOString() }))!;
  }

  async markRead(id: string, viewerId: string): Promise<void> {
    const conversation = await this.require(id);
    const role = await this.roleOf(conversation, viewerId);
    if (!role) throw new ForbiddenException('Bu sohbete erişimin yok.');
    await this.conversations.update(id, role === 'customer' ? { unreadCustomer: 0 } : { unreadProvider: 0 });
  }

  async upload(id: string, dto: UploadAttachmentDto): Promise<{ id: string }> {
    const conversation = await this.require(id);
    if (!(await this.roleOf(conversation, dto.senderId))) throw new ForbiddenException('Bu sohbete fotoğraf gönderemezsin.');
    return { id: await this.attachments.save({ ownerId: dto.senderId, conversationId: id, contentType: dto.contentType, data: dto.data }) };
  }

  /** Everything the person is party to, for the "Verilerimi indir" export. */
  async exportFor(accountId: string, providerId: string | null) {
    const mine = [
      ...(await this.conversations.find({ customerId: accountId })),
      ...(providerId ? await this.conversations.find({ providerId }) : []),
    ];
    const out = [];
    for (const conversation of mine) {
      const rows = await this.messages.find({ conversationId: conversation.id }, { sort: { createdAt: 1 } });
      out.push({ conversation, messages: rows.map((m) => (m.deletedAt ? { ...m, text: '[silindi]' } : m)) });
    }
    return out;
  }

  private async require(id: string): Promise<ConversationEntity> {
    const c = await this.conversations.get(id);
    if (!c) throw new NotFoundException('Sohbet bulunamadı.');
    return c;
  }

  private async ownMessage(messageId: string, senderId: string): Promise<MessageEntity> {
    const m = await this.messages.get(messageId);
    if (!m) throw new NotFoundException('Mesaj bulunamadı.');
    if (m.senderId !== senderId) throw new ForbiddenException('Yalnızca kendi mesajını değiştirebilirsin.');
    if (m.deletedAt) throw new BadRequestException('Mesaj zaten silinmiş.');
    return m;
  }

  private async roleOf(conversation: ConversationEntity, userId: string): Promise<'customer' | 'provider' | null> {
    if (userId === conversation.customerId) return 'customer';
    const account = await this.accounts.find(userId);
    return account?.providerId === conversation.providerId ? 'provider' : null;
  }
}
