import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'reviews', timestamps: true })
export class ReviewDoc {
  /** Legacy unique key (one review per order). Direct reviews get a generated value. */
  @Prop({ required: true, unique: true }) orderId: string;
  @Prop({ default: '' }) userId: string;
  @Prop({ required: true, index: true }) providerId: string;
  @Prop({ default: 'Kullanıcı' }) authorName: string;
  @Prop({ required: true, min: 0.5, max: 5 }) rating: number;
  @Prop({ default: '' }) comment: string;
  @Prop({ type: [String], default: [] }) tags: string[];
}

export type ReviewDocument = ReviewDoc & Document;
export const ReviewSchema = SchemaFactory.createForClass(ReviewDoc);
