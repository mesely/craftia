import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.GRPC,
    options: {
      package: 'notification',
      protoPath: join(__dirname, 'proto/notification.proto'),
      url: '0.0.0.0:50056',
    },
  });
  await app.listen();
  console.log('🔔 Notification Microservice (Mongoose Full CRUD) listening on port 50056');
}
bootstrap();