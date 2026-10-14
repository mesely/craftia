import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

/** Collection and legacy field names (categoryId/cityId) are kept so old orders stay readable. */
@Schema({ collection: 'orders', timestamps: true })
export class OrderDoc {
  @Prop({ required: true, index: true }) userId: string;
  @Prop({ required: true }) categoryId: string;
  @Prop({ required: true }) cityId: string;
  @Prop({ required: true }) description: string;
  @Prop({ default: 'PENDING' }) status: string;
  @Prop() providerId: string;
  @Prop() providerName: string;
  @Prop() subType: string;
  @Prop() contactPhone: string;
  @Prop({ type: { type: String, enum: ['Point'] }, coordinates: { type: [Number] } }, )
  location?: { type: 'Point'; coordinates: number[] };
}

export type OrderDocument = OrderDoc & Document;
export const OrderSchema = SchemaFactory.createForClass(OrderDoc);
