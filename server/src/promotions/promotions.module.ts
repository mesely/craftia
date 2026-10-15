import { Module } from '@nestjs/common';
import { AccountsModule } from '../accounts/accounts.module';
import { ProvidersModule } from '../providers/providers.module';
import { PromotionsController } from './promotions.controller';
import { PromotionsService } from './promotions.service';

@Module({
  imports: [AccountsModule, ProvidersModule.register()],
  controllers: [PromotionsController],
  providers: [PromotionsService],
})
export class PromotionsModule {}
