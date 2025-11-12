import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PurchasesService } from './purchases.service';
import { PurchasesController } from './purchases.controller';
import { Purchase, PurchaseSchema } from './purchase.entity';
import { PurchaseItemModule } from '../purchase-item/purchase-item.module';
import { ProductStocksModule } from '../product-stocks/product-stocks.module';
import { StockMovementModule } from '../stock-movement/stock-movement.module';
import { SupplierCreditsModule } from '../supplier-credits/supplier-credits.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: Purchase.name, schema: PurchaseSchema }]),
    PurchaseItemModule,
    ProductStocksModule,
    StockMovementModule,
    SupplierCreditsModule,
  ],
  controllers: [PurchasesController],
  providers: [PurchasesService],
  exports: [MongooseModule],
})
export class PurchasesModule {}
