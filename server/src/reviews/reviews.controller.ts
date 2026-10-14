import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { CreateReviewDto, ListReviewsDto } from './reviews.dto';
import { ReviewsService } from './reviews.service';

@Controller('providers/:providerId/reviews')
export class ReviewsController {
  constructor(private readonly reviews: ReviewsService) {}

  @Get()
  list(@Param('providerId') providerId: string, @Query() q: ListReviewsDto) {
    return this.reviews.list(providerId, q.page, q.limit);
  }

  @Post()
  create(@Param('providerId') providerId: string, @Body() body: CreateReviewDto) {
    return this.reviews.create(providerId, body);
  }
}
