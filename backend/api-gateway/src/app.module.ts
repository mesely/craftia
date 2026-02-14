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
          protoPath: join(process.cwd(), 'proto/user.proto'),
          url: 'user-service:50052', // Docker servis ismi
        },
      },
      {
        name: 'PROVIDER_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'provider',
          protoPath: join(process.cwd(), 'proto/provider.proto'),
          url: 'provider-service:50051', // Docker servis ismi
        },
      },
      {
        name: 'ORDER_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'order',
          protoPath: join(process.cwd(), 'proto/order.proto'),
          url: 'order-service:50054', // Docker servis ismi
        },
      },
      {
        name: 'REVIEW_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'review',
          protoPath: join(process.cwd(), 'proto/review.proto'),
          url: 'review-service:50055', // Docker servis ismi
        },
      },
      {
        name: 'NOTIFICATION_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'notification',
          protoPath: join(process.cwd(), 'proto/notification.proto'),
          url: 'notification-service:50056', // Docker servis ismi
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