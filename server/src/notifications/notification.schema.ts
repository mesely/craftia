import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'notifications', timestamps: true })
export class NotificationDoc {
  @Prop({ required: true }) type: string;
  @Prop({ required: true, index: true }) recipient: string;
  @Prop({ required: true }) title: string;
  @Prop({ required: true }) body: string;
  @Prop({ default: Date.now }) sentAt: Date;
}

export type NotificationDocument = NotificationDoc & Document;
export const NotificationSchema = SchemaFactory.createForClass(NotificationDoc);
