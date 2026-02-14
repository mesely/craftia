import { Module } from '@nestjs/common';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { join } from 'path';

// Controller & Service Importları
import { UserGatewayController } from './user/user.controller';
import { UserGatewayService } from './user/user.service';
import { ProviderGatewayController } from './provider/provider.controller';
import { ProviderGatewayService } from './provider/provider.service';
import { OrderGatewayController } from './order/order.controller';
import { OrderGatewayService } from './order/order.service';
import { ReviewGatewayController } from './review/review.controller';
import { ReviewGatewayService } from './review/review.service';
import { NotificationGatewayController } from './notification/notification.controller';
import { NotificationGatewayService } from './notification/notification.service';

@Module({
  imports: [
    ClientsModule.register([
      {
        name: 'USER_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'user',
          // process.cwd() konteyner içindeki /usr/src/app dizinini işaret eder
          protoPath: join(process.cwd(), 'proto/user.proto'),
          url: 'usta-user-service:50052', // Docker-compose servis adı
        },
      },
      {
        name: 'PROVIDER_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'provider',
          protoPath: join(process.cwd(), 'proto/provider.proto'),
          url: 'usta-provider-service:50051', // Docker-compose servis adı
        },
      },
      {
        name: 'ORDER_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'order',
          protoPath: join(process.cwd(), 'proto/order.proto'),
          url: 'usta-order-service:50054', // Docker-compose servis adı
        },
      },
      {
        name: 'REVIEW_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'review',
          protoPath: join(process.cwd(), 'proto/review.proto'),
          url: 'usta-review-service:50055', // Docker-compose servis adı
        },
      },
      {
        name: 'NOTIFICATION_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'notification',
          protoPath: join(process.cwd(), 'proto/notification.proto'),
          url: 'usta-notification-service:50056', // Docker-compose servis adı
        },
      },
    ]),
  ],
  controllers: [
    UserGatewayController,
    ProviderGatewayController,
    OrderGatewayController,
    ReviewGatewayController,
    NotificationGatewayController,
  ],
  providers: [
    UserGatewayService,
    ProviderGatewayService,
    OrderGatewayService,
    ReviewGatewayService,
    NotificationGatewayService,
  ],
})
export class AppModule {}