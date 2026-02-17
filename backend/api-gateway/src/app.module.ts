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
          // Hem yerelde hem konteynerda proto klasörünü bulması için __dirname + relative path en sağlamıdır
          protoPath: join(__dirname, '../../proto/user.proto'),
          // HF'de yan odadaki servise gitmek için 127.0.0.1 kullanılır
          url: process.env.USER_SERVICE_URL || '127.0.0.1:50052',
        },
      },
      {
        name: 'PROVIDER_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'provider',
          protoPath: join(__dirname, '../../proto/provider.proto'),
          url: process.env.PROVIDER_SERVICE_URL || '127.0.0.1:50051',
        },
      },
      {
        name: 'ORDER_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'order',
          protoPath: join(__dirname, '../../proto/order.proto'),
          url: process.env.ORDER_SERVICE_URL || '127.0.0.1:50054',
        },
      },
      {
        name: 'REVIEW_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'review',
          protoPath: join(__dirname, '../../proto/review.proto'),
          url: process.env.REVIEW_SERVICE_URL || '127.0.0.1:50055',
        },
      },
      {
        name: 'NOTIFICATION_PACKAGE',
        transport: Transport.GRPC,
        options: {
          package: 'notification',
          protoPath: join(__dirname, '../../proto/notification.proto'),
          url: process.env.NOTIFICATION_SERVICE_URL || '127.0.0.1:50056',
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