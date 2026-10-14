import { Injectable } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { Page, toPage } from '../common/pagination';
import { SEED_REVIEWS } from '../data/seed';
import { ReviewEntity } from './review.types';
import { ReviewsRepository } from './reviews.repository';

@Injectable()
export class MockReviewsRepository extends ReviewsRepository {
  private readonly reviews: ReviewEntity[] = SEED_REVIEWS.map((r) => ({ ...r }));

  async list(providerId: string, page: number, limit: number): Promise<Page<ReviewEntity>> {
    const all = this.reviews
      .filter((r) => r.providerId === providerId)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
    return toPage(all.slice((page - 1) * limit, page * limit), all.length, page, limit);
  }

  async create(data: Omit<ReviewEntity, 'id' | 'createdAt'>): Promise<ReviewEntity> {
    const review: ReviewEntity = { ...data, id: randomUUID(), createdAt: new Date().toISOString() };
    this.reviews.push(review);
    return review;
  }

  async stats(providerId: string) {
    const own = this.reviews.filter((r) => r.providerId === providerId);
    const count = own.length;
    const average = count ? own.reduce((s, r) => s + r.rating, 0) / count : 0;
    return { average: Math.round(average * 10) / 10, count };
  }
}
