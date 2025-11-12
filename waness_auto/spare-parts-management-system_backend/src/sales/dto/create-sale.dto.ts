import { IsNotEmpty, IsNumber, IsString, IsDateString, IsArray, ValidateNested, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';
import { CreateSaleItemDto } from '../../sale-item/dto/create-sale-item.dto';

export class CreateSaleDto {
  @IsDateString()
  @IsNotEmpty()
  readonly sale_date: string;

  @IsString()
  @IsNotEmpty()
  readonly warehouse_id: string;

  @IsString()
  @IsNotEmpty()
  readonly customer_name: string;

  @IsNumber()
  @IsNotEmpty()
  readonly total_amount: number;

  @IsString()
  @IsNotEmpty()
  readonly created_by: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateSaleItemDto)
  @IsOptional()
  readonly items: CreateSaleItemDto[];
}
 

