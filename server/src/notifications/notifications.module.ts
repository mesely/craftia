import { DynamicModule, Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { isMongo } from '../config/env';
import { NotificationDoc, NotificationSchema } from './notification.schema';
import { NotificationsController } from './notifications.controller';
import {
  MockNotificationsRepository, MongoNotificationsRepository, NotificationsRepository,
} from './notifications.repository';
import { NotificationsService } from './notifications.service';

@Module({})
export class NotificationsModule {
  private static cached?: DynamicModule;

  static register(): DynamicModule {
    if (NotificationsModule.cached) return NotificationsModule.cached;
    const mongo = isMongo();
    return (NotificationsModule.cached = {
      module: NotificationsModule,
      imports: mongo ? [MongooseModule.forFeature([{ name: NotificationDoc.name, schema: NotificationSchema }])] : [],
      controllers: [NotificationsController],
      providers: [
        NotificationsService,
        { provide: NotificationsRepository, useClass: mongo ? MongoNotificationsRepository : MockNotificationsRepository },
      ],
      exports: [NotificationsService],
    });
  }
}
