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
}

export const ProviderSchema = SchemaFactory.createForClass(Provider);