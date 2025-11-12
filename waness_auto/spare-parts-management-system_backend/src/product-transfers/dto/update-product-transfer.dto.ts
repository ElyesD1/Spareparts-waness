import { IsOptional, IsEnum, IsString, IsNumber } from 'class-validator';
import { TransferPriority, TransferStatus } from '../product-transfer.entity';

export class UpdateProductTransferDto {
  @IsOptional()
  @IsNumber()
  quantity?: number;

  @IsOptional()
  @IsEnum(TransferPriority)
  priority?: TransferPriority;

  @IsOptional()
  @IsEnum(TransferStatus)
  status?: TransferStatus;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  approved_by?: string;

  @IsOptional()
  @IsString()
  processed_by?: string;
}

export class ApproveTransferDto {
  @IsOptional()
  @IsString()
  notes?: string;

  @IsString()
  approved_by: string;
}

export class RejectTransferDto {
  @IsString()
  @IsOptional()
  reason?: string;

  @IsString()
  approved_by: string;
}

export class ProcessTransferDto {
  @IsOptional()
  @IsString()
  notes?: string;

  @IsString()
  processed_by: string;
}


