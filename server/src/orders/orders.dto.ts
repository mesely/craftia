import { Type } from 'class-transformer';
import { IsIn, IsNumber, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateServiceRequestDto {
  @IsString() @MinLength(1) @MaxLength(80) userId: string;
  @IsString() @IsOptional() providerId?: string;
  @IsString() @MaxLength(80) @IsOptional() customerName?: string;
  @IsString() mainType: string;
  @IsString() @IsOptional() subType?: string;
  @IsString() @MinLength(2) city: string;
  @IsString() @MinLength(10, { message: 'Açıklama en az 10 karakter olmalı.' }) @MaxLength(1000) description: string;
  @IsString() @MaxLength(20) @IsOptional() contactPhone?: string;
  @Type(() => Number) @IsNumber() @IsOptional() lat?: number;
  @Type(() => Number) @IsNumber() @IsOptional() lng?: number;
}

export class UpdateStatusDto {
  @IsIn(['ACCEPTED', 'COMPLETED', 'CANCELLED']) status: 'ACCEPTED' | 'COMPLETED' | 'CANCELLED';
  /** Who is acting: the customer who made the request, or the usta's account. */
  @IsString() @MaxLength(64) actorId: string;
}
