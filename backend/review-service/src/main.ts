import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.GRPC,
    options: {
      package: 'review',
      protoPath: join(__dirname, 'proto/review.proto'),
      url: '0.0.0.0:50055', // Review Service Port
    },
  });
  
  await app.listen();
  console.log('⭐ Review Microservice (Mongoose) is listening on port 50055');
}
bootstrap();