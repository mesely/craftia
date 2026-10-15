import { Module } from '@nestjs/common';
import { AccountsModule } from '../accounts/accounts.module';
import { ComplaintsModule } from '../complaints/complaints.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { OrdersModule } from '../orders/orders.module';
import { PrivacyController } from './privacy.controller';

@Module({
  imports: [AccountsModule, ComplaintsModule, ConversationsModule, OrdersModule.register()],
  controllers: [PrivacyController],
})
export class PrivacyModule {}
