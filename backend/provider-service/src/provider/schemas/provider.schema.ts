import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';
import { User } from './user.schema';

export type ProviderDocument = Provider & Document;

@Schema({ timestamps: true })
export class Provider {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  user: User | Types.ObjectId;

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

  @Prop({ required: true })
  lat: number;

  @Prop({ required: true })
  lng: number;

  @Prop({ default: 400 })
  openingFee: number;

  @Prop({ default: 45 })
  pricePerUnit: number;
}

export const ProviderSchema = SchemaFactory.createForClass(Provider);