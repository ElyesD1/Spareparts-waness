import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { CreditSalesService } from './credit-sales.service';
import { CreditSalesController } from './credit-sales.controller';
import { CreditSale, CreditSaleSchema } from './credit-sale.entity';
import { CreditSaleItem, CreditSaleItemSchema } from '../credit-sale-items/credit-sale-item.entity';
import { CustomersModule } from '../customers/customers.module';
import { ProductStocksModule } from '../product-stocks/product-stocks.module';
import { SalesModule } from '../sales/sales.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: CreditSale.name, schema: CreditSaleSchema },
      { name: CreditSaleItem.name, schema: CreditSaleItemSchema }
    ]),
    CustomersModule,
    ProductStocksModule,
    SalesModule
  ],
  controllers: [CreditSalesController],
  providers: [CreditSalesService],
  exports: [CreditSalesService, MongooseModule],
})
export class CreditSalesModule {}