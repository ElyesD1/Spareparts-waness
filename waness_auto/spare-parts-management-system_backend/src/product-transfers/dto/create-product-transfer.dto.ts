import { IsNotEmpty, IsNumber, IsEnum, IsOptional, IsString, Min } from 'class-validator';
import { TransferPriority } from '../product-transfer.entity';

export class CreateProductTransferDto {
  @IsNotEmpty()
  @IsString()
  product_id: string;

  @IsNotEmpty()
  @IsString()
  from_warehouse_id: string;

  @IsNotEmpty()
  @IsString()
  to_warehouse_id: string;

  @IsNotEmpty()
  @IsNumber()
  @Min(1)
  quantity: number;

  @IsEnum(TransferPriority)
  @IsOptional()
  priority?: TransferPriority = TransferPriority.NORMAL;

  @IsNotEmpty()
  @IsString()
  reason: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsNotEmpty()
  @IsString()
  requested_by: string;
}


