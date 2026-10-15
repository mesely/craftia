import { IsIn, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class SendMessageDto {
  @IsString() @MaxLength(64) senderId: string;
  @IsString() @MaxLength(2000) @IsOptional() text?: string;
  @IsString() @MaxLength(40) @IsOptional() attachmentId?: string;
  @IsString() @MaxLength(40) @IsOptional() replyToId?: string;
}

export class EditMessageDto {
  @IsString() @MaxLength(64) senderId: string;
  @IsString() @MinLength(1, { message: 'Mesaj boş olamaz.' }) @MaxLength(2000) text: string;
}

export class UploadAttachmentDto {
  @IsString() @MaxLength(64) senderId: string;
  @IsIn(['image/jpeg', 'image/png', 'image/webp'], { message: 'Yalnızca JPEG, PNG veya WebP fotoğraf gönderilebilir.' })
  contentType: string;
  @IsString() @Matches(/^[A-Za-z0-9+/=\s]+$/) data: string;
}
