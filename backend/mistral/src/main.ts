import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger } from '@nestjs/common';

/**
 * BOOTSTRAP: AI Temizlik Motoru
 * gRPC'den tamamen arındırıldı, sadece HTTP üzerinden çalışıp DB'yi temizler.
 */
async function bootstrap() {
  const logger = new Logger('AI_Cleaning_Engine');

  try {
    const app = await NestFactory.create(AppModule);

    // 1. Güvenlik ve Ağ Ayarları (CORS & Prefix)
    app.enableCors({
      origin: '*',
      methods: 'GET,POST',
    });
    app.setGlobalPrefix('api/v1');

    // 2. Kapatma Kancaları
    app.enableShutdownHooks();

    // 3. Başlatma (Port 3005 yapıyoruz ki senin ana Gateway/Frontend 3000'deyse çakışmasın)
    const PORT = 3005; 
    await app.listen(PORT); 
    
    logger.log(`🟢 [SİSTEM] AI Temizlik Motoru Mermi Gibi Çalışıyor! Port: ${PORT}`);
    logger.log(`🎯 Tetiklemek için Postman'den POST at: http://localhost:${PORT}/api/v1/cleanup/start`);

  } catch (error) {
    logger.error('❌ [KRİTİK HATA] Motor ateşlenirken bir sorun oluştu:', error);
    process.exit(1);
  }
}

bootstrap();