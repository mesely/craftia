import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { randomUUID } from 'crypto';
import { Model } from 'mongoose';
import { NotificationDoc, NotificationDocument } from './notification.schema';
import { NotificationEntity } from './notification.types';

export type NewNotification = Omit<NotificationEntity, 'id' | 'sentAt'>;

export abstract class NotificationsRepository {
  abstract add(data: NewNotification): Promise<NotificationEntity>;
  abstract listFor(recipient: string): Promise<NotificationEntity[]>;
}

@Injectable()
export class MockNotificationsRepository extends NotificationsRepository {
  private readonly items: NotificationEntity[] = [];

  async add(data: NewNotification): Promise<NotificationEntity> {
    const n = { ...data, id: randomUUID(), sentAt: new Date().toISOString() };
    this.items.unshift(n);
    return n;
  }

  async listFor(recipient: string): Promise<NotificationEntity[]> {
    return this.items.filter((n) => n.recipient === recipient);
  }
}

@Injectable()
export class MongoNotificationsRepository extends NotificationsRepository {
  constructor(@InjectModel(NotificationDoc.name) private readonly model: Model<NotificationDocument>) {
    super();
  }

  async add(data: NewNotification): Promise<NotificationEntity> {
    return this.toEntity((await this.model.create(data)).toObject());
  }

  async listFor(recipient: string): Promise<NotificationEntity[]> {
    const docs = await this.model.find({ recipient }).sort({ createdAt: -1 }).limit(50).lean().exec();
    return docs.map((d) => this.toEntity(d));
  }

  private toEntity(d: any): NotificationEntity {
    return {
      id: String(d._id),
      type: d.type === 'EMAIL' ? 'EMAIL' : 'PUSH',
      recipient: d.recipient,
      title: d.title,
      body: d.body,
      sentAt: new Date(d.sentAt ?? d.createdAt ?? Date.now()).toISOString(),
    };
  }
}
