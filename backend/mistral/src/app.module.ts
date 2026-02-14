import { Module, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Connection } from 'mongoose';
import { AIModule } from './ai.module'; // Kendi göbeğini kesen AI modülümüz

/**
 * APP MODULE: Dükkanın Ana Kartı
 * Tüm alt modüllerin ve veritabanı bağlantısının toplandığı merkez.
 */
@Module({
  imports: [
    // 🛡️ Enterprise Seviye Veritabanı Bağlantısı
    MongooseModule.forRoot('mongodb+srv://selmanyilmaz:morinyo1907@cs306cluster.h6hnm1n.mongodb.net/usta_db?retryWrites=true&w=majority', {
      // 1. Ağ Ayarları: Mistral AI uzun sürerse DB bağlantısı zaman aşımına uğramasın diye
      serverSelectionTimeoutMS: 5000, // 5 saniye içinde Atlas'ı bulamazsa sonsuza kadar beklemez, hatayı basar
      socketTimeoutMS: 45000,         // Uzun süren sorgularda soketin açık kalma süresi
      
      // 2. Bağlantı Fabrikası (Connection Factory): Terminalde Canlı İzleme
      connectionFactory: (connection: Connection) => {
        const dbLogger = new Logger('MongoDB_Atlas');
        
        connection.on('connected', () => {
          dbLogger.log('🟢 [Veritabanı] Atlas bağlantısı mermi gibi kuruldu!');
        });
        
        connection.on('error', (err) => {
          dbLogger.error(`❌ [Veritabanı] Kritik bağlantı hatası: ${err.message}`);
        });
        
        connection.on('disconnected', () => {
          dbLogger.warn('⚠️ [Veritabanı] Bağlantı koptu! Tekrar deneniyor...');
        });

        return connection;
      },
    }),
    
    // Yapay Zeka Motoru
    AIModule,
  ],
})
export class AppModule implements OnApplicationBootstrap {
  private readonly logger = new Logger(AppModule.name);

  // Uygulama tamamen ayağa kalktığında tetiklenen son güvenlik onayı
  onApplicationBootstrap() {
    this.logger.log('🚀 [SİSTEM] Dükkanın ana motoru yüklendi, tüm modüller devrede ve operasyona hazır.');
  }
}