import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CreditSaleItem, CreditSaleItemSchema } from './credit-sale-item.entity';

@Module({
  imports: [MongooseModule.forFeature([{ name: CreditSaleItem.name, schema: CreditSaleItemSchema }])],
  exports: [MongooseModule],
})
export class CreditSaleItemsModule {}