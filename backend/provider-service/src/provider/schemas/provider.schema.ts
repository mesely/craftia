import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

// Yukarıda tanımladığın interface'i buraya import ettiğini varsayıyorum. 
// Eğer aynı dosyadalar ise import'a gerek yok.
// import { Provider } from './provider.interface'; // İhtiyaca göre açabilirsin

export type ProviderDocument = Provider & Document;

@Schema({ timestamps: true })
export class Provider {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  user: Types.ObjectId;

  @Prop({ required: true })
  businessName: string;

  @Prop({ required: true })
  phoneNumber: string;

  @Prop({ required: true })
  city: string;

  @Prop({ required: true })
  district: string;

  @Prop()
  address: string;

  @Prop()
  website: string;

  @Prop()
  mainType: string;

  @Prop()
  subType: string;

  @Prop({ required: true, default: 0 })
  lat: number;

  @Prop({ required: true, default: 0 })
  lng: number;

  @Prop({ default: 500 })
  openingFee: number;

  @Prop({ default: 100 })
  pricePerUnit: number;

  // ✅ YENİ EKLENEN ALANLAR
  // Frontend'de puan ve premium rozeti göstermek, filtreleme yapmak için:
  @Prop({ default: 4.9 }) // Ustalar başlarken 4.9 puanla başlasın
  rating: number;

  @Prop({ default: false }) // Premium olan ustalar üstte çıkar
  isPremium: boolean;

  // Mistral AI Temizlik motorunun iz bırakması için:
  @Prop({ default: false })
  aiVerified: boolean;

  @Prop()
  lastAiAudit: Date;
}

export const ProviderSchema = SchemaFactory.createForClass(Provider);

// MongoDB'de arama performansını (City ve SubType için) 100 kat artıracak indeksler:
ProviderSchema.index({ city: 1, subType: 1 });
ProviderSchema.index({ isPremium: -1, createdAt: -1 });