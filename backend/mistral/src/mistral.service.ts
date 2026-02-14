import { Injectable, Logger } from '@nestjs/common';
import axios from 'axios';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Provider, ProviderDocument } from './schemas/provider.schema';

@Injectable()
export class AIClassifierService {
  private readonly logger = new Logger(AIClassifierService.name);
  
  private readonly API_KEY = 'cvgWJHqibrjDCDghrORZLRwARCtevMoj'; 
  private readonly API_URL = 'https://api.mistral.ai/v1/chat/completions';

  // ✅ SİSTEM ANAYASASI
  private readonly VALID_MAP: Record<string, string[]> = {
    TECHNICAL: ['elektrikçi', 'su tesisatçısı', 'klima servisi', 'kombi tamiri'],
    CONSTRUCTION: ['pimapenci', 'parke laminant', 'boyacı', 'alçı sıva', 'dekorasyon'],
    TECH: ['televizyon tamiri', 'bilgisayar tamiri', 'beyaz eşya tamiri', 'elektronik tamiri', 'telefon tamiri'],
    LIFE: ['ev temizliği', 'ev işi', 'ev yemeği', 'evcil hayvan bakımı'],
    EDUCATION: ['özel ders', 'matematik öğretmeni', 'yabancı dil öğretmeni']
  };

  constructor(
    @InjectModel(Provider.name) private providerModel: Model<ProviderDocument>,
  ) {}

  /**
   * CORE OPERATION: runCleanup
   */
  async runCleanup() {
    this.logger.log('🧠 [AI DEEP CLEAN] V8 Motoru ateşlendi! Cursor ve Batching devrede...');
    
    const cursor = this.providerModel.find().cursor();
    const stats = { scanned: 0, regexFiltered: 0, aiUpdated: 0, errors: 0 };
    
    let batch: ProviderDocument[] = [];
    const BATCH_SIZE = 15; // API'yi yormamak için 15'erli paketler

    for await (const usta of cursor) {
      stats.scanned++;

      // 1. HİBRİT ML: Önce Yerel Kural Motoru (Regex) baksın.
      const localDecision = this.localRegexFilter(usta.businessName);
      
      if (localDecision) {
        await this.updateProvider(usta._id, localDecision.mainType, localDecision.subType);
        this.logger.log(`⚡ [HIZLI ÇÖZÜM] "${usta.businessName}" -> ${localDecision.subType} (Regex)`);
        stats.regexFiltered++;
        continue;
      }

      batch.push(usta);

      if (batch.length >= BATCH_SIZE) {
        await this.processBatch(batch, stats);
        batch = []; 
        await new Promise(r => setTimeout(r, 2000)); // Rate Limit Molası
      }
    }

    if (batch.length > 0) {
      await this.processBatch(batch, stats);
    }

    this.logger.log(`🏁 [OPERASYON BİTTİ] Taranan: ${stats.scanned} | Regex: ${stats.regexFiltered} | AI: ${stats.aiUpdated} | Hata: ${stats.errors}`);
    return stats;
  }

  /**
   * BATCH PROCESSING
   */
  private async processBatch(batch: ProviderDocument[], stats: any) {
    this.logger.log(`📦 [BATCH] ${batch.length} adet işletme Mistral'e gönderiliyor...`);
    
    const aiResults = await this.thinkWithMistralBatch(batch);
    
    if (!aiResults || !aiResults.results) {
      stats.errors += batch.length;
      return;
    }

    for (const result of aiResults.results) {
      const usta = batch.find(u => u._id.toString() === result.id);
      if (!usta) continue;

      const validated = this.strictValidator(result.mainType, result.subType);
      if (validated && (validated.subType !== usta.subType)) {
        await this.updateProvider(usta._id, validated.mainType, validated.subType);
        this.logger.log(`🎯 [AI ÇÖZDÜ] "${usta.businessName}": ${usta.subType} -> ${validated.subType}`);
        stats.aiUpdated++;
      }
    }
  }

  /**
   * MISTRAL BATCH ENGINE - KATEGORİ ZORLAMALI
   */
  private async thinkWithMistralBatch(batch: ProviderDocument[]) {
    const inputList = batch.map(u => ({ id: u._id, name: u.businessName, current: u.subType }));
    
    // Anayasayı JSON formatında stringe çevirip direk modelin gözüne sokuyoruz
    const validMapString = JSON.stringify(this.VALID_MAP, null, 2);

    const prompt = `
      GÖREV: Aşağıdaki işletmelerin listesini analiz et ve kategorilerini belirle.

      ZORUNLU KATEGORİ HARİTASI (ANA KATEGORİ VE ALT KATEGORİLER):
      Sen SADECE aşağıdaki JSON haritasında belirtilen eşleşmeleri kullanabilirsin. Başka hiçbir kelime veya kategori uyduramazsın.
      ${validMapString}
      
      MANTIK VE AYRIM (Chain of Thought):
      - "Pano, Tesisat, Avize, Kablo" -> TECHNICAL / elektrikçi
      - "LCD, TV, Kart Tamiri, Uydu" -> TECH / elektronik tamiri
      - "Pimapen, Cam, PVC" -> CONSTRUCTION / pimapenci
      
      GİRDİ LİSTESİ:
      ${JSON.stringify(inputList)}
      
      ÇIKTI FORMATI:
      SADECE aşağıdaki yapıda bir JSON objesi döndür. Başka metin yazma:
      {
        "results": [
          { "id": "...", "mainType": "...", "subType": "..." }
        ]
      }
    `;

    try {
      const res = await axios.post(
        this.API_URL,
        {
          model: "open-mistral-7b",
          messages: [
            { role: "system", content: "You are a strict data classification agent. You NEVER invent categories outside the provided map." },
            { role: "user", content: prompt }
          ],
          response_format: { type: "json_object" },
          temperature: 0.0 // 0.0 yaparak yaratıcılığı TAMAMEN öldürdük. Sadece haritadan seçecek.
        },
        { headers: { 'Authorization': `Bearer ${this.API_KEY}`, 'Content-Type': 'application/json' } }
      );

      return JSON.parse(res.data.choices[0].message.content);
    } catch (e) {
      this.logger.error(`❌ Batch API Error: ${e.message}`);
      return null;
    }
  }

  /**
   * LOCAL REGEX FILTER
   */
  private localRegexFilter(name: string) {
    const lowerName = name.toLowerCase();
    
    if (lowerName.includes('pimapen') || lowerName.includes('cam balkon')) return { mainType: 'CONSTRUCTION', subType: 'pimapenci' };
    if (lowerName.includes('boya') || lowerName.includes('badana')) return { mainType: 'CONSTRUCTION', subType: 'boyacı' };
    if (lowerName.includes('özel ders') || lowerName.includes('öğretmen')) return { mainType: 'EDUCATION', subType: 'özel ders' };
    if (lowerName.includes('klima')) return { mainType: 'TECHNICAL', subType: 'klima servisi' };
    
    return null;
  }

  /**
   * VALIDATOR (Son Kale)
   */
  private strictValidator(main: string, sub: string) {
    if (!main || !sub) return null;
    const m = main.toUpperCase().trim();
    const s = sub.toLowerCase().trim();

    if (this.VALID_MAP[m] && this.VALID_MAP[m].includes(s)) return { mainType: m, subType: s };
    
    for (const [key, subs] of Object.entries(this.VALID_MAP)) {
      if (subs.includes(s)) return { mainType: key, subType: s };
    }
    return null;
  }

  /**
   * DB Güncelleyici
   */
  private async updateProvider(id: any, mainType: string, subType: string) {
    await this.providerModel.findByIdAndUpdate(id, {
      $set: { mainType, subType, aiVerified: true, lastAiAudit: new Date() }
    });
  }
}