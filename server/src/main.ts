import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import type { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { loadConfig } from './config/env';

async function bootstrap() {
  const config = loadConfig();
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.enableCors();
  // Chat photos arrive as base64 JSON (downscaled on the phone, 3 MB cap enforced in the service).
  app.useBodyParser('json', { limit: '6mb' });
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true }));
  await app.listen(config.port, '0.0.0.0');
  Logger.log(`Usta API http://localhost:${config.port} (data source: ${config.dataSource})`, 'Bootstrap');
}

bootstrap();
