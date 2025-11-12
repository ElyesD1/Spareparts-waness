import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SaleItemService } from './sale-item.service';
import { SaleItemController } from './sale-item.controller';
import { SaleItem, SaleItemSchema } from './sale-item.entity';
import { ProductStocksModule } from '../product-stocks/product-stocks.module';
import { StockMovementModule } from '../stock-movement/stock-movement.module';

@Module({
  imports: [MongooseModule.forFeature([{ name: SaleItem.name, schema: SaleItemSchema }]), ProductStocksModule, StockMovementModule],
  controllers: [SaleItemController],
  providers: [SaleItemService],
  exports: [SaleItemService, MongooseModule],
})
export class SaleItemModule {}
