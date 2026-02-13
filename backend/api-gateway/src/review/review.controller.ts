import { Controller, Get, Post, Body, Param, Delete } from '@nestjs/common';
import { ReviewGatewayService } from './review.service';

@Controller('api/v1/reviews')
export class ReviewGatewayController {
  constructor(private readonly reviewService: ReviewGatewayService) {}

  @Post()
  create(@Body() data: any) {
    return this.reviewService.create(data);
  }

  @Get('provider/:providerId')
  getProviderReviews(@Param('providerId') providerId: string) {
    return this.reviewService.getProviderReviews(providerId);
  }

  @Get('user/:userId')
  getUserReviews(@Param('userId') userId: string) {
    return this.reviewService.getUserReviews(userId);
  }

  @Delete(':id')
  delete(@Param('id') id: string) {
    return this.reviewService.delete(id);
  }
}