import { Type } from 'class-transformer';
import { IsIn, IsNumber, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateServiceRequestDto {
  @IsString() @MinLength(1) @MaxLength(80) userId: string;
  @IsString() @IsOptional() providerId?: string;
  @IsString() mainType: string;
  @IsString() @IsOptional() subType?: string;
  @IsString() @MinLength(2) city: string;
  @IsString() @MinLength(10, { message: 'Açıklama en az 10 karakter olmalı.' }) @MaxLength(1000) description: string;
  @IsString() @MaxLength(20) @IsOptional() contactPhone?: string;
  @Type(() => Number) @IsNumber() @IsOptional() lat?: number;
  @Type(() => Number) @IsNumber() @IsOptional() lng?: number;
}

export class UpdateStatusDto {
  /** Without accounts the public API only lets a request be cancelled. */
  @IsIn(['CANCELLED']) status: 'CANCELLED';
}
