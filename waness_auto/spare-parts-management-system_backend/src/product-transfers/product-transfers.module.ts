import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProductTransfersService } from './product-transfers.service';
import { ProductTransfersController } from './product-transfers.controller';
import { ProductTransfer, ProductTransferSchema } from './product-transfer.entity';
import { ProductStocksModule } from '../product-stocks/product-stocks.module';
import { StockMovementModule } from '../stock-movement/stock-movement.module';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: ProductTransfer.name, schema: ProductTransferSchema }]),
    ProductStocksModule,
    StockMovementModule,
  ],
  controllers: [ProductTransfersController],
  providers: [ProductTransfersService],
  exports: [ProductTransfersService, MongooseModule],
})
export class ProductTransfersModule {}
