import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { isValidCoordinate } from '../common/geo';
import { NotificationsService } from '../notifications/notifications.service';
import { ProvidersService } from '../providers/providers.service';
import { CreateServiceRequestDto } from './orders.dto';
import { OrdersRepository } from './orders.repository';

@Injectable()
export class OrdersService {
  constructor(
    private readonly repo: OrdersRepository,
    private readonly providers: ProvidersService,
    private readonly notifications: NotificationsService,
  ) {}

  async create(dto: CreateServiceRequestDto) {
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
    await this.notifications.record({
      type: 'PUSH',
      recipient: dto.providerId ?? dto.userId,
      title: 'Yeni hizmet talebi',
      body: request.description.slice(0, 120),
    });
    return request;
  }

  listByUser(userId?: string) {
    if (!userId) throw new BadRequestException('userId gerekli.');
    return this.repo.listByUser(userId);
  }

  async cancel(id: string) {
    const existing = await this.repo.findById(id);
    if (!existing) throw new NotFoundException('Talep bulunamadı.');
    if (existing.status === 'COMPLETED') throw new BadRequestException('Tamamlanan talep iptal edilemez.');
    return (await this.repo.setStatus(id, 'CANCELLED'))!;
  }
}
