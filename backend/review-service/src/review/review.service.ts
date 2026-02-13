import { Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { RpcException } from '@nestjs/microservices';
import { Review, ReviewDocument } from './schemas/review.schema';

@Injectable()
export class ReviewService {
  private readonly logger = new Logger(ReviewService.name);

  constructor(
    @InjectModel(Review.name) private reviewModel: Model<ReviewDocument>
  ) {}

  async create(data: any) {
    const { orderId, rating } = data;

    // 1. Puan Kontrolü
    if (rating < 0.5 || rating > 5.0) {
      throw new RpcException('Puan 0.5 ile 5.0 arasında olmalıdır.');
    }

    // 2. Mükerrer Kontrolü
    const existing = await this.reviewModel.findOne({ orderId });
    if (existing) {
      throw new RpcException('Bu sipariş için zaten yorum yapılmış.');
    }

    try {
      const newReview = new this.reviewModel(data);
      const saved = await newReview.save();
      
      return this.mapToProto(saved);
    } catch (error) {
      this.logger.error(`Yorum oluşturma hatası: ${error.message}`);
      throw new RpcException('Yorum kaydedilemedi.');
    }
  }

  async getProviderReviews(providerId: string) {
    const reviews = await this.reviewModel.find({ providerId }).sort({ createdAt: -1 }).exec();
    return { reviews: reviews.map(this.mapToProto) };
  }

  async getUserReviews(userId: string) {
    const reviews = await this.reviewModel.find({ userId }).sort({ createdAt: -1 }).exec();
    return { reviews: reviews.map(this.mapToProto) };
  }

  async delete(id: string) {
    const result = await this.reviewModel.findByIdAndDelete(id);
    return { success: !!result };
  }

  // Helper: DB nesnesini Proto formatına çevirir
  private mapToProto(doc: ReviewDocument) {
    return {
      id: doc._id.toString(),
      orderId: doc.orderId,
      userId: doc.userId,
      providerId: doc.providerId,
      rating: doc.rating,
      comment: doc.comment,
      tags: doc.tags,
      createdAt: (doc as any).createdAt.toISOString(),
    };
  }
}