import { IsInt, IsNotEmpty, IsString, MinLength, Length } from 'class-validator';

export class ResetPasswordDto {
  @IsInt()
  @IsNotEmpty()
  userId: number;

  @IsNotEmpty()
  otp: string;

  @IsNotEmpty()
  newPassword: string;

  @IsNotEmpty()
  confirmPassword: string;
} 

