import { Injectable, NotFoundException, PayloadTooLargeException } from '@nestjs/common';
import { Store, StoreFactory } from '../common/store';
import { AttachmentEntity } from '../conversations/conversation.types';

export const MAX_ATTACHMENT_BYTES = 3 * 1024 * 1024;

/** Photos (chat pictures, usta work photos). Stored as base64; the phone downscales before upload. */
@Injectable()
export class AttachmentsService {
  private readonly store: Store<AttachmentEntity>;

  constructor(stores: StoreFactory) {
    this.store = stores.collection<AttachmentEntity>('attachments');
  }

  async save(input: { ownerId: string; conversationId: string | null; contentType: string; data: string }): Promise<string> {
    const data = input.data.replace(/\s/g, '');
    const size = Math.floor((data.length * 3) / 4);
    if (size > MAX_ATTACHMENT_BYTES) throw new PayloadTooLargeException('Fotoğraf çok büyük (en fazla 3 MB).');
    const a = await this.store.insert({
      conversationId: input.conversationId,
      ownerId: input.ownerId,
      contentType: input.contentType,
      data,
      size,
      createdAt: new Date().toISOString(),
    });
    return a.id;
  }

  async get(id: string): Promise<AttachmentEntity | null> {
    return this.store.get(id);
  }

  async binary(id: string): Promise<{ contentType: string; buffer: Buffer }> {
    const a = await this.store.get(id);
    if (!a) throw new NotFoundException('Fotoğraf bulunamadı.');
    return { contentType: a.contentType, buffer: Buffer.from(a.data, 'base64') };
  }

  remove(id: string): Promise<boolean> {
    return this.store.remove(id);
  }
}
