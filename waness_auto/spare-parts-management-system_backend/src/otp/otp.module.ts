import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Otp, OtpSchema } from './entities/otp.entity';
import { OtpService } from './otp.service';
import { OtpController } from './otp.controller';
import { EmailService } from '../email/email.service';
import { User, UserSchema } from 'src/users/user.entity';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule, 
    MongooseModule.forFeature([
      { name: Otp.name, schema: OtpSchema },
      { name: User.name, schema: UserSchema }
    ])
  ],
  providers: [OtpService, EmailService],
  controllers: [OtpController],
  exports: [OtpService, MongooseModule],
})
export class OtpModule {} 