import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // CORS ayarı: Frontend'in (Next.js) erişebilmesi için şart
  app.enableCros({
    origin: '*', // Geliştirme aşamasında her yerden gelen isteğe izin ver
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
  });

  const port = process.env.PORT || 3000;
  await app.listen(port);
  
  Logger.log(`🚀 API Gateway is running on: http://localhost:${port}`);
  Logger.log(`🔗 Connected to: User(50052), Provider(50051), Order(50054), Review(50055), Notification(50056)`);
}
bootstrap();