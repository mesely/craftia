import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Notification, NotificationDocument } from './schemas/notification.schema';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    @InjectModel(Notification.name) private readonly model: Model<NotificationDocument>,
  ) {}

  // --- Orijinal Gönderim Mantığı ---

  async sendEmail(data: any) {
    this.logger.log(`📧 [EMAIL] Kime: ${data.to} | Konu: ${data.subject}`);
    
    const log = new this.model({
      type: 'EMAIL',
      recipient: data.to,
      title: data.subject,
      body: data.body,
    });
    const saved = await log.save();
    return { success: true, messageId: saved._id.toString() };
  }

  async sendPush(data: any) {
    this.logger.log(`🔔 [PUSH] UserID: ${data.userId} | Başlık: ${data.title}`);
    
    const log = new this.model({
      type: 'PUSH',
      recipient: data.userId,
      title: data.title,
      body: data.body,
    });
    const saved = await log.save();
    return { success: true, messageId: saved._id.toString() };
  }

  // --- Yeni Full CRUD İşlemleri ---

  async getHistory(userId: string) {
    const logs = await this.model.find({ recipient: userId }).sort({ createdAt: -1 }).exec();
    return { logs: logs.map(this.mapToProto) };
  }

  async findOne(id: string) {
    const log = await this.model.findById(id).exec();
    if (!log) throw new NotFoundException('Bildirim kaydı bulunamadı');
    return this.mapToProto(log);
  }

  async update(id: string, data: any) {
    const updated = await this.model.findByIdAndUpdate(id, data, { new: true }).exec();
    if (!updated) throw new NotFoundException('Güncellenecek kayıt bulunamadı');
    return this.mapToProto(updated);
  }

  async delete(id: string) {
    const result = await this.model.findByIdAndDelete(id).exec();
    return { success: !!result };
  }

  private mapToProto(doc: NotificationDocument) {
    return {
      id: doc._id.toString(),
      type: doc.type,
      recipient: doc.recipient,
      title: doc.title,
      body: doc.body,
      sentAt: (doc as any).createdAt.toISOString(),
    };
  }
}