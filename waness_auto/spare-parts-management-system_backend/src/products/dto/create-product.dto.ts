import { IsNotEmpty, IsString, IsOptional, IsNumber, IsEnum } from 'class-validator';
import { ProductCategory, ProductBrand } from '../products.entity';

export class CreateProductDto {
  @IsNotEmpty() @IsString() name: string;
  @IsNotEmpty() @IsString() reference_code: string;

  @IsOptional() @IsEnum(ProductBrand) brand?: ProductBrand;
  @IsOptional() @IsEnum(ProductCategory) category?: ProductCategory;
  @IsNotEmpty() @IsNumber() unit_price: number;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsString() image?: string;
}


