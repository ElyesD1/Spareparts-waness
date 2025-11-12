import { Controller, Post, Body, ValidationPipe } from '@nestjs/common';
import { OtpService } from './otp.service';
import { ResetPasswordDto } from 'src/auth/dto/reset-password.dto';

@Controller('otp')
export class OtpController {
  constructor(private readonly otpService: OtpService) {}

  @Post('forgot-password')
  async forgotPassword(@Body() dto: { email: string }) {
    return this.otpService.forgotPasswordOtpByEmail(dto.email);
  }
  

  @Post('verify')
  async verify(@Body() dto: { email: string, otp: string }) {
    return this.otpService.verifyOtp(dto.email, dto.otp);
  }

  @Post('reset-password')
  async resetPassword(@Body(ValidationPipe) dto: ResetPasswordDto) {
    return this.otpService.resetPassword(dto);
  }

} 
