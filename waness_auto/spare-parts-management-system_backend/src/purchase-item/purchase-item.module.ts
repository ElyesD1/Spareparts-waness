import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PurchaseItemService } from './purchase-item.service';
import { PurchaseItemController } from './purchase-item.controller';
import { PurchaseItem, PurchaseItemSchema } from './purchase-item.entity';
import { ProductStocksModule } from '../product-stocks/product-stocks.module';
import { StockMovementModule } from '../stock-movement/stock-movement.module';

@Module({
  imports: [MongooseModule.forFeature([{ name: PurchaseItem.name, schema: PurchaseItemSchema }]), ProductStocksModule, StockMovementModule],
  controllers: [PurchaseItemController],
  providers: [PurchaseItemService],
  exports: [PurchaseItemService, MongooseModule],
})
export class PurchaseItemModule {}
