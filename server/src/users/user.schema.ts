import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ collection: 'users', timestamps: true })
export class UserDoc {
  @Prop() email: string;
  @Prop() firstName: string;
  @Prop() lastName: string;
  @Prop() phone: string;
  // Credentials from the legacy collection are never read or exposed by this API.
}

export type UserDocument = UserDoc & Document;
export const UserSchema = SchemaFactory.createForClass(UserDoc);
