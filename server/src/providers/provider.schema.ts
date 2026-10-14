import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

/** Field names match the legacy `providers` collection so existing data keeps working. */
@Schema({ collection: 'providers', timestamps: true })
export class ProviderDoc {
  @Prop({ required: true }) businessName: string;
  @Prop({ required: true }) phoneNumber: string;
  @Prop() mainType: string;
  @Prop() subType: string;
  @Prop() city: string;
  @Prop() district: string;
  @Prop() address: string;
  @Prop() lat: number;
  @Prop() lng: number;
  @Prop({ default: 0 }) rating: number;
  @Prop({ default: 0 }) reviewCount: number;
  @Prop({ default: false }) isPremium: boolean;
  /** Legacy name for "verified". */
  @Prop({ default: false }) aiVerified: boolean;
  @Prop({ default: '' }) about: string;
  @Prop() profileImage: string;
  @Prop([String]) portfolioImages: string[];
  /** Legacy shape is a map of "service" -> "min-max"; normalised on read. */
  @Prop({ type: Object }) priceList: unknown;
}

export type ProviderDocument = ProviderDoc & Document;
export const ProviderSchema = SchemaFactory.createForClass(ProviderDoc);
ProviderSchema.index({ mainType: 1, subType: 1, city: 1 });
ProviderSchema.index({ isPremium: -1, rating: -1 });
