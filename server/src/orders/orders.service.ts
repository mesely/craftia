import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { AccountsService } from '../accounts/accounts.service';
import { isValidCoordinate } from '../common/geo';
import { ConversationsService } from '../conversations/conversations.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ProvidersService } from '../providers/providers.service';
import { CreateServiceRequestDto, UpdateStatusDto } from './orders.dto';
import { OrdersRepository } from './orders.repository';
import { RequestStatus, ServiceRequestEntity } from './order.types';

/** A request plus what the list screen needs about its chat. */
export interface ServiceRequestView extends ServiceRequestEntity {
  conversationId: string | null;
  customerName: string;
  lastMessageAt: string;
  lastMessageText: string;
  unread: number;
}

const SYSTEM_TEXT: Record<string, string> = {
  ACCEPTED: 'Usta talebi kabul etti.',
  COMPLETED: 'İş tamamlandı olarak işaretlendi.',
  CANCELLED: 'Talep iptal edildi.',
};

@Injectable()
export class OrdersService {
  constructor(
    private readonly repo: OrdersRepository,
    private readonly providers: ProvidersService,
    private readonly notifications: NotificationsService,
    private readonly conversations: ConversationsService,
    private readonly accounts: AccountsService,
  ) {}

  async create(dto: CreateServiceRequestDto): Promise<ServiceRequestView> {
    let providerName: string | null = null;
    if (dto.providerId) {
      providerName = (await this.providers.get(dto.providerId)).businessName;
    }
    const located = isValidCoordinate(dto.lat, dto.lng);
    const request = await this.repo.create({
      userId: dto.userId,
      providerId: dto.providerId ?? null,
      providerName,
      mainType: dto.mainType,
      subType: dto.subType ?? '',
      city: dto.city,
      description: dto.description.trim(),
      contactPhone: dto.contactPhone ?? '',
      lat: located ? dto.lat! : null,
      lng: located ? dto.lng! : null,
    });
    let conversationId: string | null = null;
    if (dto.providerId) {
      const conversation = await this.conversations.openForRequest({
        requestId: request.id,
        customerId: dto.userId,
        customerName: dto.customerName?.trim() || 'Müşteri',
        providerId: dto.providerId,
        providerName: providerName ?? '',
        subject: dto.subType ?? '',
        description: request.description,
      });
      conversationId = conversation.id;
    }
    await this.notifications.record({
      type: 'PUSH',
      recipient: dto.providerId ?? dto.userId,
      title: 'Yeni hizmet talebi',
      body: request.description.slice(0, 120),
    });
    return {
      ...request,
      conversationId,
      customerName: dto.customerName?.trim() || 'Müşteri',
      lastMessageAt: request.createdAt,
      lastMessageText: `Hizmet Talebi: ${request.description}`,
      unread: 0,
    };
  }

  /** Customer view (userId) or usta inbox (providerId). */
  async list(userId?: string, providerId?: string): Promise<ServiceRequestView[]> {
    if (!userId && !providerId) throw new BadRequestException('userId veya providerId gerekli.');
    const rows = userId ? await this.repo.listByUser(userId) : await this.repo.listByProvider(providerId!);
    const chats = await this.conversations.byRequestIds(rows.map((r) => r.id));
    return rows
      .map((r) => {
        const c = chats.get(r.id);
        return {
          ...r,
          conversationId: c?.id ?? null,
          customerName: c?.customerName ?? '',
          lastMessageAt: c?.lastMessageAt ?? r.createdAt,
          lastMessageText: c?.lastMessageText ?? '',
          unread: c ? (userId ? c.unreadCustomer : c.unreadProvider) : 0,
        };
      })
      .sort((a, b) => b.lastMessageAt.localeCompare(a.lastMessageAt));
  }

  async changeStatus(id: string, dto: UpdateStatusDto): Promise<ServiceRequestEntity> {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundException('Talep bulunamadı.');
    const actorIsCustomer = dto.actorId === existing.userId;
    const actorIsProvider =
      !actorIsCustomer && !!existing.providerId && (await this.accounts.find(dto.actorId))?.providerId === existing.providerId;
    if (!actorIsCustomer && !actorIsProvider) throw new ForbiddenException('Bu talebi değiştirme yetkin yok.');

    const from = existing.status;
    if (from === 'COMPLETED' || from === 'CANCELLED') throw new BadRequestException('Bu talep artık değiştirilemez.');
    const allowed: Record<RequestStatus, RequestStatus[]> = {
      PENDING: actorIsProvider ? ['ACCEPTED', 'CANCELLED'] : ['CANCELLED'],
      ACCEPTED: ['COMPLETED', 'CANCELLED'],
      COMPLETED: [],
      CANCELLED: [],
    };
    if (!allowed[from].includes(dto.status)) throw new BadRequestException('Bu işlem şu anda yapılamaz.');

    const updated = (await this.repo.setStatus(id, dto.status))!;
    await this.conversations.systemMessage(id, SYSTEM_TEXT[dto.status]);
    return updated;
  }

  /** Used by the privacy export. */
  async exportFor(userId: string, providerId: string | null) {
    return providerId ? this.list(undefined, providerId) : this.list(userId);
  }
}
