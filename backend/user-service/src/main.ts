import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.GRPC,
    options: {
      package: 'user',
      protoPath: join(__dirname, 'proto/user.proto'), // __dirname daha güvenlidir
      url: '0.0.0.0:50052', // User Service Portu
    },
  });
  await app.listen();
  console.log('✅ User Microservice (Mongoose) Ayakta! (Port 50052)');
}
bootstrap();