import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CreditPaymentsService } from './credit-payments.service';
import { CreditPaymentsController } from './credit-payments.controller';
import { CreditPayment, CreditPaymentSchema } from './credit-payment.entity';
import { CreditSalesModule } from '../credit-sales/credit-sales.module';
import { CustomersModule } from '../customers/customers.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: CreditPayment.name, schema: CreditPaymentSchema }]),
    CreditSalesModule,
    CustomersModule
  ],
  controllers: [CreditPaymentsController],
  providers: [CreditPaymentsService],
  exports: [CreditPaymentsService, MongooseModule],
})
export class CreditPaymentsModule {}