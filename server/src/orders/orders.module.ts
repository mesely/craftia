import { DynamicModule, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { isMongo } from '../config/env';
import { AccountsModule } from '../accounts/accounts.module';
import { ConversationsModule } from '../conversations/conversations.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { ProvidersModule } from '../providers/providers.module';
import { OrderDoc, OrderSchema } from './order.schema';
import { OrdersController } from './orders.controller';
import { MockOrdersRepository, MongoOrdersRepository, OrdersRepository } from './orders.repository';
import { OrdersService } from './orders.service';

@Module({})
export class OrdersModule {
  static register(): DynamicModule {
    const mongo = isMongo();
    return {
      module: OrdersModule,
      imports: [
        ProvidersModule.register(),
        AccountsModule,
        ConversationsModule,
        NotificationsModule.register(),
        ...(mongo ? [MongooseModule.forFeature([{ name: OrderDoc.name, schema: OrderSchema }])] : []),
      ],
      controllers: [OrdersController],
      exports: [OrdersService],
      providers: [
        OrdersService,
        { provide: OrdersRepository, useClass: mongo ? MongoOrdersRepository : MockOrdersRepository },
      ],
    };
  }
}
