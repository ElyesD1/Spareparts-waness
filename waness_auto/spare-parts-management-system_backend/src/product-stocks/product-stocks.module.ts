import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProductStocksController } from './product-stocks.controller';
import { ProductStocksService } from './product-stocks.service';
import { ProductStock, ProductStockSchema } from './product-stock.entity';

@Module({
  imports: [MongooseModule.forFeature([{ name: ProductStock.name, schema: ProductStockSchema }])],
  controllers: [ProductStocksController],
  providers: [ProductStocksService],
  exports: [ProductStocksService, MongooseModule],
})
export class ProductStocksModule {}
