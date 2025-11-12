import { IsOptional, IsString, IsNumber, IsEnum } from 'class-validator';
import { ProductCategory, ProductBrand } from '../products.entity';

export class UpdateProductDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsString() reference_code?: string;
  @IsOptional() @IsString() barcode?: string;
  @IsOptional() @IsEnum(ProductBrand) brand?: ProductBrand;
  @IsOptional() @IsEnum(ProductCategory) category?: ProductCategory;
  @IsOptional() @IsNumber() unit_price?: number;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsString() image?: string;
  @IsOptional() @IsNumber() supplier_id?: number;
  @IsOptional() @IsNumber() supplier_price?: number;
}



