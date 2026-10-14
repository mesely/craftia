import { Type } from 'class-transformer';
import { IsInt, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class ListReviewsDto {
  @Type(() => Number) @IsInt() @Min(1) @IsOptional() page: number = 1;
  @Type(() => Number) @IsInt() @Min(1) @Max(50) @IsOptional() limit: number = 10;
}

export class CreateReviewDto {
  @Type(() => Number) @IsNumber() @Min(1) @Max(5) rating: number;
  @IsString() @MaxLength(1000) @IsOptional() comment?: string;
  @IsString() @MaxLength(60) @IsOptional() authorName?: string;
  @IsString() @MaxLength(60) @IsOptional() userId?: string;
}
