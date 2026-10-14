import { DynamicModule, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { isMongo } from '../config/env';
import { ProvidersModule } from '../providers/providers.module';
import { ReviewDoc, ReviewSchema } from './review.schema';
import { ReviewsController } from './reviews.controller';
import { MockReviewsRepository } from './reviews.mock.repository';
import { MongoReviewsRepository } from './reviews.mongo.repository';
import { ReviewsRepository } from './reviews.repository';
import { ReviewsService } from './reviews.service';

@Module({})
export class ReviewsModule {
  static register(): DynamicModule {
    const mongo = isMongo();
    return {
      module: ReviewsModule,
      imports: [
        ProvidersModule.register(),
        ...(mongo ? [MongooseModule.forFeature([{ name: ReviewDoc.name, schema: ReviewSchema }])] : []),
      ],
      controllers: [ReviewsController],
      providers: [
        ReviewsService,
        { provide: ReviewsRepository, useClass: mongo ? MongoReviewsRepository : MockReviewsRepository },
      ],
    };
  }
}
