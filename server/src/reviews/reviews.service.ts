import { Injectable } from '@nestjs/common';
import { ProvidersService } from '../providers/providers.service';
import { CreateReviewDto } from './reviews.dto';
import { ReviewsRepository } from './reviews.repository';

@Injectable()
export class ReviewsService {
  constructor(
    private readonly repo: ReviewsRepository,
    private readonly providers: ProvidersService,
  ) {}

  async list(providerId: string, page: number, limit: number) {
    await this.providers.get(providerId); // 404 for unknown providers
    const [result, stats] = await Promise.all([this.repo.list(providerId, page, limit), this.repo.stats(providerId)]);
    return { ...result, averageRating: stats.average };
  }

  async create(providerId: string, dto: CreateReviewDto) {
    await this.providers.get(providerId);
    const review = await this.repo.create({
      providerId,
      rating: dto.rating,
      comment: dto.comment?.trim() ?? '',
      authorName: dto.authorName?.trim() || 'Kullanıcı',
      tags: [],
      userId: dto.userId,
    });
    const stats = await this.repo.stats(providerId);
    await this.providers.updateReviewStats(providerId, stats.average, stats.count);
    return review;
  }
}
