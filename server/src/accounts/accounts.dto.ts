import { IsEmail, IsIn, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class UpsertAccountDto {
  /** Generated on the device. */
  @IsString() @Matches(/^[a-zA-Z0-9_-]{8,64}$/, { message: 'Geçersiz hesap kimliği.' }) id: string;
  @IsIn(['customer', 'provider']) role: 'customer' | 'provider';
  @IsString() @MinLength(2) @MaxLength(80) name: string;
  @IsString() @MaxLength(20) @IsOptional() phone?: string;
  @IsEmail({}, { message: 'E-posta adresi geçersiz.' }) @IsOptional() email?: string;
  @IsString() @MaxLength(40) @IsOptional() providerId?: string;
}
