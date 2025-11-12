import {
  Injectable,
  UnauthorizedException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import * as bcrypt from 'bcryptjs';
import { LoginDto } from 'src/users/dto/login.dto';
import { CreateUserDto } from 'src/users/dto/create-user.dto';
import { User, UserDocument } from 'src/users/user.entity';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { OtpService } from 'src/otp/otp.service';
import { ResetPasswordDto } from './dto/reset-password.dto';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    private otpService: OtpService,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async validateUser(email: string, pass: string): Promise<any> {
    const user = await this.usersService.findByEmail(email);
    if (user && (await bcrypt.compare(pass, user.password_hash))) {
      // Convert Mongoose document to plain object
      const userObj = user.toObject ? user.toObject() : user;
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      const { password_hash, ...result } = userObj;
      return result;
    }
    return null;
  }

  async login(loginDto: LoginDto) {
    const user = await this.validateUser(loginDto.email, loginDto.password);
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }
    
    const userId = user._id?.toString() || user.id?.toString();
    const payload = { email: user.email, sub: userId, role: user.role };
    const token = this.jwtService.sign(payload);
    
    // Log the token to the terminal
    console.log('=== LOGIN SUCCESS ===');
    console.log('User Email:', user.email);
    console.log('User ID:', userId);
    console.log('User Role:', user.role);
    console.log('Access Token:', token);
    console.log('=====================');
    
    return {
      access_token: token,
    };
  }

  async signup(createUserDto: CreateUserDto) {
    const salt = await bcrypt.genSalt();
    const hashedPassword = await bcrypt.hash(createUserDto.password, salt);
    
    // Create user data object with password_hash instead of password
    const userData = {
      name: createUserDto.name,
      email: createUserDto.email,
      password_hash: hashedPassword,
      phone_number: createUserDto.phone_number,
      role: createUserDto.role,
    };
    
    const user = await this.usersService.create(userData);
    return user;
  }

  async forgotPassword(email: string) {
    return await this.otpService.forgotPasswordOtpByEmail(email);
  }

  async resetPassword(dto: ResetPasswordDto) {
    return await this.otpService.resetPassword(dto);
  }

  getUsersService() {
    return this.usersService;
  }
}

