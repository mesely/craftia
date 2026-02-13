import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type NotificationDocument = Notification & Document;

@Schema({ timestamps: true })
export class Notification {
  @Prop({ required: true })
  type: string; // 'EMAIL' or 'PUSH'

  @Prop({ required: true })
  recipient: string; // Email adresi veya User ID

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  body: string;

  @Prop({ default: Date.now })
  sentAt: Date;
}

export const NotificationSchema = SchemaFactory.createForClass(Notification);