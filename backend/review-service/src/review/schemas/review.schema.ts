import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type ReviewDocument = Review & Document;

@Schema({ timestamps: true })
export class Review {
  @Prop({ required: true, unique: true }) // Bir siparişe tek yorum
  orderId: string;

  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  providerId: string;

  @Prop({ required: true, min: 0.5, max: 5.0 })
  rating: number;

  @Prop({ default: '' })
  comment: string;

  @Prop({ type: [String], default: [] })
  tags: string[];
}

export const ReviewSchema = SchemaFactory.createForClass(Review);