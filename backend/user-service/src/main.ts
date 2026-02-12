import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { AppModule } from './app.module';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.GRPC,
    options: {
      package: 'user', // user.proto içindeki package ismiyle aynı olmalı
      // Ortak proto klasörüne giden yol
      protoPath: join(process.cwd(), '../proto/user.proto'), 
      url: '0.0.0.0:50052', // User Service için port 50052
    },
  });
  
  await app.listen();
  console.log('✅ User Microservice is listening on port 50052...');
}
bootstrap();


