import { Controller, Get, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { CategoriesController } from './categories/categories.controller';
import { DatabaseModule } from './config/database.module';
import { loadConfig } from './config/env';
import { NotificationsModule } from './notifications/notifications.module';
import { OrdersModule } from './orders/orders.module';
import { ProvidersModule } from './providers/providers.module';
import { ReviewsModule } from './reviews/reviews.module';
import { UsersModule } from './users/users.module';

@Controller('health')
class HealthController {
  constructor(private readonly config: ConfigService) {}

  @Get()
  check() {
    return { status: 'ok', dataSource: this.config.get<string>('dataSource') };
  }
}

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [loadConfig] }),
    DatabaseModule.register(),
    ProvidersModule.register(),
    ReviewsModule.register(),
    OrdersModule.register(),
    NotificationsModule.register(),
    UsersModule.register(),
  ],
  controllers: [HealthController, CategoriesController],
})
export class AppModule {}
