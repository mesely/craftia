import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { randomUUID } from 'crypto';
import { Model } from 'mongoose';
import { Page, toPage } from '../common/pagination';
import { ReviewDoc, ReviewDocument } from './review.schema';
import { ReviewEntity } from './review.types';
import { ReviewsRepository } from './reviews.repository';

@Injectable()
export class MongoReviewsRepository extends ReviewsRepository {
  constructor(@InjectModel(ReviewDoc.name) private readonly model: Model<ReviewDocument>) {
    super();
  }

  async list(providerId: string, page: number, limit: number): Promise<Page<ReviewEntity>> {
    const [docs, total] = await Promise.all([
      this.model.find({ providerId }).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit).lean().exec(),
      this.model.countDocuments({ providerId }).exec(),
    ]);
    return toPage(docs.map((d) => this.toEntity(d)), total, page, limit);
  }

  async create(data: Omit<ReviewEntity, 'id' | 'createdAt'> & { userId?: string }): Promise<ReviewEntity> {
    const doc = await this.model.create({ ...data, orderId: `direct-${randomUUID()}` });
    return this.toEntity(doc.toObject());
  }

  async stats(providerId: string) {
    const [res] = await this.model
      .aggregate([{ $match: { providerId } }, { $group: { _id: null, avg: { $avg: '$rating' }, n: { $sum: 1 } } }])
      .exec();
    return { average: res ? Math.round(res.avg * 10) / 10 : 0, count: res?.n ?? 0 };
  }

  private toEntity(d: any): ReviewEntity {
    return {
      id: String(d._id),
      providerId: d.providerId,
      authorName: d.authorName || 'Kullanıcı',
      rating: d.rating,
      comment: d.comment ?? '',
      tags: d.tags ?? [],
      createdAt: new Date(d.createdAt ?? Date.now()).toISOString(),
    };
  }
}
