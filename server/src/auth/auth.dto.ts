import { Type } from 'class-transformer';
import { IsEmail, IsIn, IsOptional, IsString, MaxLength, MinLength, ValidateNested } from 'class-validator';
import { CreateProviderDto } from '../providers/providers.dto';

export class RegisterDto {
  @IsIn(['customer', 'provider']) role: 'customer' | 'provider';
  @IsString() @MinLength(2, { message: 'Adını yaz.' }) @MaxLength(80) name: string;
  @IsString() @MinLength(10, { message: 'Telefon numarası geçersiz.' }) @MaxLength(20) phone: string;
  @IsEmail({}, { message: 'E-posta adresi geçersiz.' }) email: string;
  @IsString() @MinLength(6, { message: 'Şifre en az 6 karakter olmalı.' }) @MaxLength(128) password: string;
  /** Required for ustas: the listing that is created together with the account. */
  @ValidateNested() @Type(() => CreateProviderDto) @IsOptional() provider?: CreateProviderDto;
}

export class LoginDto {
  @IsString() @MinLength(3) @MaxLength(120) identifier: string;
  @IsString() @MinLength(1) @MaxLength(128) password: string;
}

export class UpgradeDto {
  @ValidateNested() @Type(() => CreateProviderDto) provider: CreateProviderDto;
}

/** Sign-in with a Firebase ID token (Google, Apple or SMS). New people also say who they are. */
export class FirebaseLoginDto {
  @IsString() @MinLength(20) @MaxLength(4096) idToken: string;
  @IsIn(['customer', 'provider']) @IsOptional() role?: 'customer' | 'provider';
  @IsString() @MinLength(2) @MaxLength(80) @IsOptional() name?: string;
  @IsString() @MinLength(10) @MaxLength(20) @IsOptional() phone?: string;
  @IsEmail({}, { message: 'E-posta adresi geçersiz.' }) @IsOptional() email?: string;
  @ValidateNested() @Type(() => CreateProviderDto) @IsOptional() provider?: CreateProviderDto;
}
