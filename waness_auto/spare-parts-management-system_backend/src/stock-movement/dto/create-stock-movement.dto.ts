import { IsInt, IsEnum, IsOptional, IsNumber, Min, IsString } from 'class-validator';
import { PartialType } from '@nestjs/mapped-types';

export enum MovementType {
  TRANSFER = 'transfer',
  PURCHASE = 'purchase',
  ADJUSTMENT = 'adjustment',
  RETURN = 'return',
  SALE = 'sale', // Added for sales movements
}

export class CreateStockMovementDto {
  @IsString() product_id: string;
  @IsOptional() @IsString() from_warehouse_id?: string;
  @IsOptional() @IsString() to_warehouse_id?: string;
  @IsString() user_id: string;
  @IsInt() @Min(1) quantity: number;
  @IsEnum(MovementType) movement_type: MovementType;
  @IsOptional() @IsString() note?: string;
  @IsOptional() @IsString() source_type?: string; // Added for tracking source (sale, purchase, etc.)
  @IsOptional() @IsString() source_id?: string; // Added for linking to source document
  @IsOptional() movement_date?: Date;
}


