import { Controller, Post, Body, ValidationPipe, Get, UseGuards, Req } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from '../users/dto/login.dto';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { JwtAuthGuard } from './jwt.guard';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  async login(@Body(ValidationPipe) loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Post('signup')
  async signup(@Body(ValidationPipe) createUserDto: CreateUserDto) {
    return this.authService.signup(createUserDto);
  }

  @Post('forgot-password')
  async forgotPassword(@Body(ValidationPipe) forgotPasswordDto: ForgotPasswordDto) {
    return this.authService.forgotPassword(forgotPasswordDto.email);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getMe(@Req() req) {
    // req.user.sub is set by JwtStrategy (contains userId)
    const userId = req.user.sub;
    console.log('[AuthController] /me - userId from JWT:', userId);
    
    const user = await this.authService.getUsersService().findByIdWithWarehouse(userId);
    if (!user) {
      console.log('[AuthController] /me - User not found for ID:', userId);
      return null;
    }
    
    console.log('[AuthController] /me - User found:', user.email);
    
    // Extract warehouse info if populated
    let warehouseName: string | null = null;
    let warehouseId: string | null = null;
    
    if (user.warehouse_id) {
      if (typeof user.warehouse_id === 'object' && 'name' in user.warehouse_id) {
        // Populated warehouse object
        warehouseName = (user.warehouse_id as any).name;
        warehouseId = (user.warehouse_id as any)._id?.toString();
      } else {
        // Just the ID
        warehouseId = user.warehouse_id.toString();
      }
    }
    
    return {
      id: user._id?.toString() || user.id,
      name: user.name,
      email: user.email,
      phone_number: user.phone_number,
      role: user.role,
      warehouse_id: warehouseId,
      warehouse_name: warehouseName,
    };
  }
} 
