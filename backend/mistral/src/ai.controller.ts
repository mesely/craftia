import { 
  Controller, 
  Post, 
  Get, 
  HttpCode, 
  HttpStatus, 
  Logger 
} from '@nestjs/common';
import { AIClassifierService } from './mistral.service';

/**
 * AI KONTROLCÜSÜ (Controller)
 * Mistral AI temizlik operasyonunu dış dünyaya (HTTP) açan API kapısı.
 * REST standartlarına ve Asenkron (Fire-and-Forget) mimariye tam uyumludur.
 */
@Controller('cleanup')
export class AIController {
  private readonly logger = new Logger(AIController.name);

  constructor(private readonly aiService: AIClassifierService) {}

  /**
   * Temizlik Operasyonunu Başlat
   * Route: POST /api/v1/cleanup/start
   * Dönüş Kodu: 202 ACCEPTED (İşlem alındı, arka planda sürüyor)
   */
  @Post('start')
  @HttpCode(HttpStatus.ACCEPTED) // 202: HTTP standartlarında "İsteği aldım, işliyorum ama henüz bitmedi" demektir.
  async start() {
    this.logger.log('🚀 [TETİKLEYİCİ] AI Temizlik isteği alındı, motor arka planda ateşleniyor...');
    
    // Asenkron Fire-and-Forget (Ateşle ve Unut) Mimarisi
    // Veritabanı taraması uzun süreceği için client'ı (tarayıcı/Postman) bekletmiyoruz.
    this.aiService.runCleanup()
      .then((res) => {
        this.logger.log(`✅ [OPERASYON BAŞARILI] İşlem Sonucu: ${JSON.stringify(res)}`);
      })
      .catch((err) => {
        this.logger.error(`❌ [KRİTİK HATA] AI Operasyonu yarıda kesildi: ${err.message}`, err.stack);
      });

    // İstemciye anında cevap dönüyoruz ki Timeout'a düşmesin.
    return { 
      status: 'accepted',
      code: HttpStatus.ACCEPTED,
      message: 'Mistral AI temizlik motoru mermi gibi çalışmaya başladı. Logları terminalden izleyebilirsin usta!',
      timestamp: new Date().toISOString()
    };
  }

  /**
   * Sağlık Kontrolü (Health Check)
   * Route: GET /api/v1/cleanup/health
   * Dükkanın yapay zeka kapısı açık mı diye ping atmak için.
   */
  @Get('health')
  @HttpCode(HttpStatus.OK)
  healthCheck() {
    this.logger.log('🩺 [SAĞLIK KONTROLÜ] Yapay Zeka motoru pinglendi.');
    return { 
      service: 'AI_Cleaning_Engine',
      status: 'online', 
      message: 'Motor çalışıyor ve operasyona hazır usta.',
      timestamp: new Date().toISOString()
    };
  }
}