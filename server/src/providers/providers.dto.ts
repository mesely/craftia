import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize, IsArray, IsIn, IsInt, IsNumber, IsOptional, IsString, Max, MaxLength, Min, MinLength, ValidateNested,
} from 'class-validator';

const emptyToUndefined = ({ value }: { value: unknown }) =>
  value === '' || value === 'all' || value == null ? undefined : value;

export class ListProvidersDto {
  @Type(() => Number) @IsInt() @Min(1) @IsOptional() page: number = 1;
  @Type(() => Number) @IsInt() @Min(1) @Max(50) @IsOptional() limit: number = 10;
  @Transform(emptyToUndefined) @IsString() @IsOptional() mainType?: string;
  @Transform(emptyToUndefined) @IsString() @IsOptional() subType?: string;
  @Transform(emptyToUndefined) @IsString() @IsOptional() city?: string;
  @Transform(emptyToUndefined) @IsIn(['nearest', 'rating', 'recommended']) @IsOptional()
  sortMode: 'nearest' | 'rating' | 'recommended' = 'nearest';
  @Transform(emptyToUndefined) @Type(() => Number) @IsNumber() @Min(1) @Max(500) @IsOptional() distance?: number;
  @Transform(emptyToUndefined) @Type(() => Number) @IsNumber() @Min(-90) @Max(90) @IsOptional() userLat?: number;
  @Transform(emptyToUndefined) @Type(() => Number) @IsNumber() @Min(-180) @Max(180) @IsOptional() userLng?: number;
  @Transform(emptyToUndefined) @IsString() @MaxLength(60) @IsOptional() q?: string;
}

export class LocationQueryDto {
  @Transform(emptyToUndefined) @Type(() => Number) @IsNumber() @IsOptional() userLat?: number;
  @Transform(emptyToUndefined) @Type(() => Number) @IsNumber() @IsOptional() userLng?: number;
}

export class PriceItemDto {
  @IsString() @MinLength(2) @MaxLength(80) serviceName: string;
  @Type(() => Number) @IsNumber() @Min(1) minPrice: number;
  @Type(() => Number) @IsNumber() @Min(1) maxPrice: number;
}

/** Provider application ("Hizmet Veren Ol"). Premium/verified/rating are never client-controlled. */
export class CreateProviderDto {
  @IsString() @MinLength(2) @MaxLength(80) businessName: string;
  @IsString() @MinLength(10) @MaxLength(20) phoneNumber: string;
  @IsString() mainType: string;
  @IsString() subType: string;
  @IsString() @MinLength(2) city: string;
  @IsString() @MinLength(2) district: string;
  @IsString() @MaxLength(200) @IsOptional() address?: string;
  @IsString() @MaxLength(500) @IsOptional() about?: string;
  @IsArray() @ArrayMaxSize(30) @ValidateNested({ each: true }) @Type(() => PriceItemDto) @IsOptional()
  priceList?: PriceItemDto[];
}
