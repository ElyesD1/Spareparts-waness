import { IsEmail, IsNotEmpty, IsString, MinLength, IsOptional, IsEnum, IsInt, IsNumber } from 'class-validator';

export class CreateUserDto {
  @IsNotEmpty()
  name: string;

  @IsEmail()
  email: string;

  @MinLength(6)
  password: string;

  @IsNumber()
  @IsNotEmpty()
  phone_number: number;

  @IsOptional()
  @IsEnum(['admin', 'manager', 'cashier', 'guest'])
  role?: 'admin' | 'manager' | 'cashier' | 'guest';

  @IsOptional()
  @IsString()
  warehouse_name?: string;
}


