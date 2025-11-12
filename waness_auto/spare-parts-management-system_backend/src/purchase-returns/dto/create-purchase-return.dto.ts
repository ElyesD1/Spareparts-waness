import { IsNotEmpty, IsNumber, IsString, IsOptional, IsDateString, IsArray, ValidateNested, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class CreatePurchaseReturnItemDto {
  @IsNotEmpty() @IsString() product_id: string;
  @IsNotEmpty() @IsNumber() @Min(1) quantity: number;
  @IsNotEmpty() @IsNumber() unit_price: number;
  @IsNotEmpty() @IsNumber() total_price: number;
}

export class CreatePurchaseReturnDto {
  @IsNotEmpty() @IsString() supplier_id: string;
  @IsNotEmpty() @IsString() warehouse_id: string;
  @IsNotEmpty() @IsDateString() return_date: string;
  @IsNotEmpty() @IsString() reason: string;
  @IsOptional() @IsString() notes?: string;
  @IsArray() @ValidateNested({ each: true }) @Type(() => CreatePurchaseReturnItemDto) items: CreatePurchaseReturnItemDto[];
} 

