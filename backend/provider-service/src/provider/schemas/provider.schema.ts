import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

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

  @Prop({ default: 4.9 })
  rating: number;

  @Prop({ default: false })
  isPremium: boolean;

  @Prop({ default: false })
  aiVerified: boolean;

  @Prop()
  lastAiAudit: Date;

  // ✅ YENİ EKLENEN ALANLAR
  @Prop()
  profileImage: string; // Tek bir profil fotoğrafı URL'i

  @Prop([String])
  portfolioImages: string[]; // Birden fazla iş fotoğrafı URL'leri

  @Prop({ type: Map, of: String }) 
  priceList: Map<string, string>; // Sözlük formatı: {"Ampul Takma": "100-200", "Boya": "5000-6000"}
}

export const ProviderSchema = SchemaFactory.createForClass(Provider);

ProviderSchema.index({ city: 1, subType: 1 });
ProviderSchema.index({ isPremium: -1, createdAt: -1 });

// Sadece bir tane IProvider interface'i yeterli
export interface IProvider {
  id?: string;
  _id?: any; // MongoDB'den gelen orijinal ID
  user?: any;
  businessName: string;
  phoneNumber: string;
  city: string;
  district: string;
  address?: string;
  website?: string;
  mainType?: string;
  subType?: string;
  lat: number;
  lng: number;
  openingFee?: number;
  pricePerUnit?: number;
  
  rating?: number;
  isPremium?: boolean;
  aiVerified?: boolean;
  lastAiAudit?: Date;
  createdAt?: Date;
  updatedAt?: Date;

  // ✅ YENİ EKLENEN RESİM VE FİYAT ALANLARI
  profileImage?: string;
  portfolioImages?: string[];
  priceList?: Record<string, string> | Map<string, string>; 
}

export interface CrawlStats {
  totalFound: number;
  newlySaved: number;
  skipped: number;
}