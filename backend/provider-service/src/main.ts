import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { AppModule } from './app.module';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
    transport: Transport.GRPC,
    options: {
      package: 'provider',
      // main.ts içindeki protoPath satırı
protoPath: join('../proto/provider.proto'),
      url: '0.0.0.0:50051',
    },
  });
  await app.listen();
  console.log('✅ Provider Microservice is listening on port 50051...');
}
bootstrap();
