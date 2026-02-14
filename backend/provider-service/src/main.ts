import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { join } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.GRPC,
    options: {
  package: 'provider',
  protoPath: join(__dirname, './proto/provider.proto'),
  url: '0.0.0.0:50051', // 🚨 Mutlaka 0.0.0.0 olmalı
},
  });
  await app.listen();
  console.log('🚀 Provider Service (gRPC) is running on port 50051');
}
bootstrap();