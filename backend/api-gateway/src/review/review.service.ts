import { Injectable, OnModuleInit, Inject } from '@nestjs/common';
import { ClientGrpc } from '@nestjs/microservices';

@Injectable()
export class ReviewGatewayService implements OnModuleInit {
  private reviewService: any;

  constructor(@Inject('REVIEW_PACKAGE') private client: ClientGrpc) {}

  onModuleInit() {
    this.reviewService = this.client.getService<any>('ReviewService');
  }

  create(data: any) {
    return this.reviewService.createReview(data);
  }

  getProviderReviews(providerId: string) {
    return this.reviewService.getProviderReviews({ providerId });
  }

  getUserReviews(userId: string) {
    return this.reviewService.getUserReviews({ userId });
  }

  delete(id: string) {
    return this.reviewService.deleteReview({ id });
  }
}