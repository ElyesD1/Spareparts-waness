import { IsNotEmpty, IsNumber, IsEnum, IsInt, IsOptional, IsString, IsDateString } from 'class-validator';

export class CreateOperationalExpenseDto {
  @IsNotEmpty() @IsString() title: string;
  @IsNotEmpty() @IsNumber() amount: number;
  @IsEnum(['rent', 'electricity', 'water', 'fuel', 'other']) type: 'rent' | 'electricity' | 'water' | 'fuel' | 'other';
  @IsString() warehouse_id: string;
  @IsInt() created_by: number;
  @IsDateString() date: string;
  @IsOptional() @IsString() note?: string;
}


