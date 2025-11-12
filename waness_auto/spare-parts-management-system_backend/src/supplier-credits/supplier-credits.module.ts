import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SupplierCreditsService } from './supplier-credits.service';
import { SupplierCreditsController } from './supplier-credits.controller';
import { SupplierCredit, SupplierCreditSchema } from './supplier-credit.entity';
import { SupplierCreditUsage, SupplierCreditUsageSchema } from './supplier-credit-usage.entity';
import { Purchase, PurchaseSchema } from '../purchases/purchase.entity';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: SupplierCredit.name, schema: SupplierCreditSchema },
      { name: SupplierCreditUsage.name, schema: SupplierCreditUsageSchema },
      { name: Purchase.name, schema: PurchaseSchema }
    ]),
  ],
  controllers: [SupplierCreditsController],
  providers: [SupplierCreditsService],
  exports: [SupplierCreditsService, MongooseModule],
})
export class SupplierCreditsModule {} 