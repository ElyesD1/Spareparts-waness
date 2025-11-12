import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PurchaseReturnsService } from './purchase-returns.service';
import { PurchaseReturnsController } from './purchase-returns.controller';
import { PurchaseReturn, PurchaseReturnSchema } from './purchase-return.entity';
import { PurchaseReturnItem, PurchaseReturnItemSchema } from './purchase-return-item.entity';
import { SupplierCredit, SupplierCreditSchema } from '../supplier-credits/supplier-credit.entity';
import { ProductStocksModule } from '../product-stocks/product-stocks.module';
import { StockMovementModule } from '../stock-movement/stock-movement.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: PurchaseReturn.name, schema: PurchaseReturnSchema },
      { name: PurchaseReturnItem.name, schema: PurchaseReturnItemSchema },
      { name: SupplierCredit.name, schema: SupplierCreditSchema }
    ]),
    ProductStocksModule,
    StockMovementModule,
  ],
  controllers: [PurchaseReturnsController],
  providers: [PurchaseReturnsService],
  exports: [PurchaseReturnsService, MongooseModule],
})
export class PurchaseReturnsModule {} 