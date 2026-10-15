import { IsEmail, IsIn, IsOptional, IsString, Matches, MaxLength, MinLength } from 'class-validator';

/** Profile data without a password: internal use and tests. */
export class UpsertAccountDto {
  @IsString() @Matches(/^[a-zA-Z0-9_-]{8,64}$/, { message: 'Geçersiz hesap kimliği.' }) id: string;
  @IsIn(['customer', 'provider']) role: 'customer' | 'provider';
  @IsString() @MinLength(2) @MaxLength(80) name: string;
  @IsString() @MaxLength(20) @IsOptional() phone?: string;
  @IsEmail({}, { message: 'E-posta adresi geçersiz.' }) @IsOptional() email?: string;
  @IsString() @MaxLength(40) @IsOptional() providerId?: string;
}

export class UpdateProfileDto {
  @IsString() @MinLength(2) @MaxLength(80) @IsOptional() name?: string;
  @IsString() @MinLength(10) @MaxLength(20) @IsOptional() phone?: string;
  @IsEmail({}, { message: 'E-posta adresi geçersiz.' }) @IsOptional() email?: string;
}
