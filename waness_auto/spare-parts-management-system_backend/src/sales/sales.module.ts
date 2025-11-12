import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SalesService } from './sales.service';
import { SalesController } from './sales.controller';
import { Sale, SaleSchema } from './sale.entity';
import { SaleItemModule } from '../sale-item/sale-item.module';

@Module({
  imports: [MongooseModule.forFeature([{ name: Sale.name, schema: SaleSchema }]), SaleItemModule],
  controllers: [SalesController],
  providers: [SalesService],
  exports: [SalesService, MongooseModule],
})
export class SalesModule {}
