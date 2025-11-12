import { IsNotEmpty, IsNumber, IsEnum, IsOptional, IsString, IsDateString } from 'class-validator';

export class CreateOperationalExpenseDto {
  @IsNotEmpty() @IsString() title: string;
  @IsNotEmpty() @IsNumber() amount: number;
  @IsEnum(['rent', 'electricity', 'water', 'fuel', 'other']) type: 'rent' | 'electricity' | 'water' | 'fuel' | 'other';
  @IsString() warehouse_id: string;
  @IsString() created_by: string;
  @IsDateString() date: string;
  @IsOptional() @IsString() note?: string;
}


