import { Controller } from '@nestjs/common';
import { GrpcMethod } from '@nestjs/microservices';
import { ReviewService } from './review.service';

@Controller()
export class ReviewController {
  constructor(private readonly reviewService: ReviewService) {}

  @GrpcMethod('ReviewService', 'CreateReview')
  createReview(data: any) {
    return this.reviewService.create(data);
  }

  @GrpcMethod('ReviewService', 'GetProviderReviews')
  getProviderReviews(data: { providerId: string }) {
    return this.reviewService.getProviderReviews(data.providerId);
  }

  @GrpcMethod('ReviewService', 'GetUserReviews')
  getUserReviews(data: { userId: string }) {
    return this.reviewService.getUserReviews(data.userId);
  }

  @GrpcMethod('ReviewService', 'DeleteReview')
  deleteReview(data: { id: string }) {
    return this.reviewService.delete(data.id);
  }
}