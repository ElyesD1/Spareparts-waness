import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProductsModule } from './products/products.module';
import { WarehousesModule } from './warehouses/warehouses.module';
import { SuppliersModule } from './suppliers/suppliers.module';
import { PurchasesModule } from './purchases/purchases.module';
import { SalesModule } from './sales/sales.module';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { mongooseConfig } from './config/mongoose.config';
import { OtpModule } from './otp/otp.module';
import { ProductStocksModule } from './product-stocks/product-stocks.module';
import { PurchaseItemModule } from './purchase-item/purchase-item.module';
import { SaleItemModule } from './sale-item/sale-item.module';
import { StockMovementController } from './stock-movement/stock-movement.controller';
import { StockMovementService } from './stock-movement/stock-movement.service';
import { StockMovementModule } from './stock-movement/stock-movement.module';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';

import { CustomersModule } from './customers/customers.module';
import { CreditSalesModule } from './credit-sales/credit-sales.module';
import { CreditPaymentsModule } from './credit-payments/credit-payments.module';
import { CreditSaleItemsModule } from './credit-sale-items/credit-sale-items.module';
import { OperationalExpensesModule } from './operational_expenses/operational-expenses.module';
import { PurchaseReturnsModule } from './purchase-returns/purchase-returns.module';
import { SupplierCreditsModule } from './supplier-credits/supplier-credits.module';
import { ProductTransfersModule } from './product-transfers/product-transfers.module';


@Module({
  imports: [
    ServeStaticModule.forRoot({
      rootPath: join(process.cwd(), 'uploads'),
      serveRoot: '/uploads',
      serveStaticOptions: {
        fallthrough: false,
        index: false,
      },
    }),
    MongooseModule.forRoot('mongodb://localhost:27017/spare_parts_management', {
      retryWrites: true,
      w: 'majority',
    }),
    ProductsModule,
    WarehousesModule,
    SuppliersModule,
    PurchasesModule,
    SalesModule,
    UsersModule,
    AuthModule,
    OtpModule,

    PurchaseItemModule,
    ProductStocksModule,
    SaleItemModule,
    StockMovementModule,
    OperationalExpensesModule,
    PurchaseReturnsModule,
    SupplierCreditsModule,
    ProductTransfersModule,
    CustomersModule,
    CreditSalesModule,
    CreditSaleItemsModule,
    CreditPaymentsModule,
  ],
  controllers: [StockMovementController],
  providers: [StockMovementService],
})
export class AppModule {}
