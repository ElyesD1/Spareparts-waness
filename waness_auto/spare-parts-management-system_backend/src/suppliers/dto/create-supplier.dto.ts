import { IsNotEmpty, IsString, IsOptional } from 'class-validator';

export class CreateSupplierDto {
  @IsNotEmpty() @IsString() name: string;
  @IsOptional() @IsString() contact_info?: string;
  @IsOptional() @IsString() address?: string;
} 

export class CreatePurchaseDto {
  readonly supplier_id: string;
  readonly date: string; // or Date if you prefer
  readonly total_amount: number;
  readonly created_by: number;
} 

