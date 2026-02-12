import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  // Gateway bir gRPC sunucusu değildir, REST API sunucusudur.
  const app = await NestFactory.create(AppModule);
  
  // CORS ayarlarını şimdiden ekleyelim, frontend bağlarken lazım olacak
  app.enableCors();

  // Gateway 3000 portunda çalışacak
  await app.listen(3000);
  console.log('🚀 API Gateway is running on http://localhost:3000');
}
bootstrap();