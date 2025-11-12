import { IsOptional, IsNumber, IsPositive } from 'class-validator';

export class UpdateSaleItemDto {
  @IsOptional()
  @IsNumber()
  sale_id?: number;

  @IsOptional()
  @IsNumber()
  product_id?: number;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  quantity?: number;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  unit_price?: number;

  // Also accept camelCase for frontend compatibility
  @IsOptional()
  @IsNumber()
  @IsPositive()
  unitPrice?: number;
} 

