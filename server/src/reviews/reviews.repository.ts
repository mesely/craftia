import { Page } from '../common/pagination';
import { ReviewEntity } from './review.types';

export abstract class ReviewsRepository {
  abstract list(providerId: string, page: number, limit: number): Promise<Page<ReviewEntity>>;
  abstract create(data: Omit<ReviewEntity, 'id' | 'createdAt'> & { userId?: string }): Promise<ReviewEntity>;
  abstract stats(providerId: string): Promise<{ average: number; count: number }>;
}
