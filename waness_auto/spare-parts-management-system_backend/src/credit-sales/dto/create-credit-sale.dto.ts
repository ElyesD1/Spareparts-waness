import { CreateCreditSaleItemDto } from '../../credit-sale-items/dto/create-credit-sale-item.dto';
import { IsNumber, IsPositive, IsArray, IsDateString, IsOptional, ValidateNested, Min, IsString } from 'class-validator';
import { Type, Transform } from 'class-transformer';

export class CreateCreditSaleDto {
  @IsString()
  readonly customer_id: string;

  @IsString()
  readonly warehouse_id: string;

  @IsOptional()
  @Transform(({ value }) => (value === '' || value === null ? undefined : value))
  @IsNumber()
  @Type(() => Number)
  readonly created_by?: number;

  @IsDateString()
  readonly sale_date: string;

  @IsNumber()
  @Type(() => Number)
  @IsPositive()
  @Min(0)
  readonly total_amount: number;

  @IsNumber()
  @Type(() => Number)
  @Min(0)
  readonly down_payment: number;

  @IsNumber()
  @Type(() => Number)
  @IsPositive()
  @Min(1)
  readonly installment_count: number;

  @IsDateString()
  readonly first_payment_date: string;

  @IsOptional()
  @IsString()
  readonly notes?: string;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @IsPositive()
  credit_amount?: number;

  @IsOptional()
  @IsNumber()
  @Type(() => Number)
  @IsPositive()
  monthly_payment?: number;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateCreditSaleItemDto)
  items: CreateCreditSaleItemDto[];
} 

