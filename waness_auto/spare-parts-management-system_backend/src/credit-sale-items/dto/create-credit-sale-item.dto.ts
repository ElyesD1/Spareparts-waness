import { IsNumber, IsPositive, Min, IsString } from 'class-validator';
import { Transform } from 'class-transformer';

export class CreateCreditSaleItemDto {
  @IsString()
  readonly product_id: string;

  @IsNumber()
  @IsPositive()
  @Min(1)
  readonly quantity: number;

  @IsNumber()
  @IsPositive()
  @Min(0)
  @Transform(({ value }) => parseFloat(value))
  readonly unit_price: number;

  // Calculate total_price automatically
  get total_price(): number {
    return this.quantity * this.unit_price;
  }
} 

