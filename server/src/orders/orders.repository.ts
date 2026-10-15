import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { randomUUID } from 'crypto';
import { Model } from 'mongoose';
import { isValidCoordinate } from '../common/geo';
import { OrderDoc, OrderDocument } from './order.schema';
import { RequestStatus, ServiceRequestEntity } from './order.types';

export type NewServiceRequest = Omit<ServiceRequestEntity, 'id' | 'createdAt' | 'status'>;

export abstract class OrdersRepository {
  abstract create(data: NewServiceRequest): Promise<ServiceRequestEntity>;
  abstract listByUser(userId: string): Promise<ServiceRequestEntity[]>;
  abstract listByProvider(providerId: string): Promise<ServiceRequestEntity[]>;
  abstract findById(id: string): Promise<ServiceRequestEntity | null>;
  abstract setStatus(id: string, status: RequestStatus): Promise<ServiceRequestEntity | null>;
}

@Injectable()
export class MockOrdersRepository extends OrdersRepository {
  private readonly items: ServiceRequestEntity[] = [];

  async create(data: NewServiceRequest) {
    const item: ServiceRequestEntity = { ...data, id: randomUUID(), status: 'PENDING', createdAt: new Date().toISOString() };
    this.items.unshift(item);
    return item;
  }

  async listByUser(userId: string) {
    return this.items.filter((i) => i.userId === userId);
  }

  async listByProvider(providerId: string) {
    return this.items.filter((i) => i.providerId === providerId);
  }

  async findById(id: string) {
    return this.items.find((i) => i.id === id) ?? null;
  }

  async setStatus(id: string, status: RequestStatus) {
    const item = this.items.find((i) => i.id === id);
    if (item) item.status = status;
    return item ?? null;
  }
}

@Injectable()
export class MongoOrdersRepository extends OrdersRepository {
  constructor(@InjectModel(OrderDoc.name) private readonly model: Model<OrderDocument>) {
    super();
  }

  async create(data: NewServiceRequest) {
    const doc = await this.model.create({
      userId: data.userId,
      categoryId: data.mainType,
      cityId: data.city,
      description: data.description,
      providerId: data.providerId ?? undefined,
      providerName: data.providerName ?? undefined,
      subType: data.subType,
      contactPhone: data.contactPhone,
      ...(isValidCoordinate(data.lat, data.lng)
        ? { location: { type: 'Point', coordinates: [data.lng!, data.lat!] } }
        : {}),
    });
    return this.toEntity(doc.toObject());
  }

  async listByUser(userId: string) {
    const docs = await this.model.find({ userId }).sort({ createdAt: -1 }).limit(100).lean().exec();
    return docs.map((d) => this.toEntity(d));
  }

  async listByProvider(providerId: string) {
    const docs = await this.model.find({ providerId }).sort({ createdAt: -1 }).limit(100).lean().exec();
    return docs.map((d) => this.toEntity(d));
  }

  async findById(id: string) {
    if (!/^[a-f\d]{24}$/i.test(id)) return null;
    const d = await this.model.findById(id).lean().exec();
    return d ? this.toEntity(d) : null;
  }

  async setStatus(id: string, status: RequestStatus) {
    if (!/^[a-f\d]{24}$/i.test(id)) return null;
    const d = await this.model.findByIdAndUpdate(id, { status }, { new: true }).lean().exec();
    return d ? this.toEntity(d) : null;
  }

  private toEntity(d: any): ServiceRequestEntity {
    const coords: number[] | undefined = d.location?.coordinates;
    return {
      id: String(d._id),
      userId: d.userId,
      providerId: d.providerId ?? null,
      providerName: d.providerName ?? null,
      mainType: d.categoryId ?? '',
      subType: d.subType ?? '',
      city: d.cityId ?? '',
      description: d.description ?? '',
      contactPhone: d.contactPhone ?? '',
      status: (d.status as RequestStatus) ?? 'PENDING',
      lat: coords?.[1] ?? null,
      lng: coords?.[0] ?? null,
      createdAt: new Date(d.createdAt ?? Date.now()).toISOString(),
    };
  }
}
