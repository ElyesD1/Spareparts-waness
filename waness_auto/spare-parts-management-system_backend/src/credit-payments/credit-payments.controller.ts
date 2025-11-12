import { Controller, Get, Post, Body, Param, UseGuards, Req, ValidationPipe } from '@nestjs/common';
import { CreditPaymentsService } from './credit-payments.service';
import { CreateCreditPaymentDto } from './dto/create-credit-payment.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';

@Controller('credit-payments')
@UseGuards(JwtAuthGuard)
export class CreditPaymentsController {
  constructor(private readonly creditPaymentsService: CreditPaymentsService) {}

  @Post()
  create(@Body() createCreditPaymentDto: CreateCreditPaymentDto, @Req() req) {
    const userId = req.user.sub;
    console.log('=== PAYMENT CREATION REQUEST ===');
    console.log('Payment data:', createCreditPaymentDto);
    console.log('User ID:', userId);
    
    try {
      return this.creditPaymentsService.create(createCreditPaymentDto, userId);
    } catch (error) {
      console.error('Payment creation failed:', error.message);
      throw error;
    }
  }

  @Post('payments')
  createPayment(@Body() paymentData: any, @Req() req) {
    const userId = req.user.sub;
    
    // Handle different payment data formats
    let paymentDto: CreateCreditPaymentDto;
    
    if (paymentData.payment) {
      // Format: {"payment": {...}}
      paymentDto = {
        ...paymentData.payment,
        received_by: userId
      };
    } else if (paymentData.credit_sale_id) {
      // Format: direct payment data
      paymentDto = {
        ...paymentData,
        received_by: userId
      };
    } else {
      throw new Error('Invalid payment data format');
    }
    
    return this.creditPaymentsService.create(paymentDto, userId);
  }

  @Get()
  findAll() {
    return this.creditPaymentsService.findAll();
  }

  @Get('credit-sale/:creditSaleId')
  findByCreditSale(@Param('creditSaleId') creditSaleId: string) {
    return this.creditPaymentsService.findByCreditSale(creditSaleId);
  }

  @Get('total-paid/:creditSaleId')
  getTotalPaid(@Param('creditSaleId') creditSaleId: string) {
    return this.creditPaymentsService.getTotalPaid(creditSaleId);
  }
}

