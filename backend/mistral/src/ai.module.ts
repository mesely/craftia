import { Module, Logger, OnModuleInit } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AIClassifierService } from './mistral.service';
import { AIController } from './ai.controller';
import { Provider, ProviderSchema } from './schemas/provider.schema';

/**
 * AI KONTROL MODÜLÜ (Enterprise Grade)
 * Bu modül, Mistral AI entegrasyonunu ve veritabanı temizleme operasyonlarını izole bir şekilde kapsar.
 * Kendi şemasına (Provider) doğrudan bağlanarak dışa bağımlılığı sıfıra indirir.
 */
@Module({
  imports: [
    // 🛡️ AI motorunun üzerinde çalışacağı MongoDB koleksiyonunu içeri alıyoruz
    MongooseModule.forFeature([{ name: Provider.name, schema: ProviderSchema }])
  ],
  controllers: [AIController],
  providers: [AIClassifierService],
  exports: [AIClassifierService], // 🚀 İleride başka modüller (örn: TaskScheduler) bu servisi kullanabilsin diye dışa açtık
})
export class AIModule implements OnModuleInit {
  private readonly logger = new Logger(AIModule.name);

  /**
   * Modül Yaşam Döngüsü Kancası (Lifecycle Hook)
   * Bu modül NestJS tarafından hafızaya yüklenip hazır olduğunda otomatik tetiklenir.
   */
  onModuleInit() {
    this.logger.log('🧠 [AI MODÜLÜ AKTİF] Mistral AI Sınıflandırma Motoru mermiye sürüldü ve tetik bekliyor!');
  }
}