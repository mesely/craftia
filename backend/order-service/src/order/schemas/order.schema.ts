import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type OrderDocument = Order & Document;

@Schema({ timestamps: true })
export class Order {
  @Prop({ required: true })
  userId: string;

  @Prop({ required: true })
  categoryId: string;

  @Prop({ required: true })
  cityId: string;

  @Prop({ required: true })
  description: string;

  @Prop({ default: 'PENDING' }) // PENDING, ACCEPTED, COMPLETED, CANCELLED
  status: string;

  // 🌍 GeoJSON Formatı (Harita sorguları için şart)
  @Prop({
    type: {
      type: String,
      enum: ['Point'],
      required: true,
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [Longitude, Latitude] sırasıyla
      required: true,
    },
  })
  location: {
    type: string;
    coordinates: number[];
  };
}

export const OrderSchema = SchemaFactory.createForClass(Order);

// 🔥 Konum bazlı arama için indeks oluşturuyoruz
OrderSchema.index({ location: '2dsphere' });