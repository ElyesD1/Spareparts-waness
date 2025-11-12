import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { Warehouse, WarehouseSchema } from './entities/warehouse.entity';
import { WarehouseService } from './warehouse.service';
import { WarehouseController } from './warehouse.controller';

@Module({
  imports: [MongooseModule.forFeature([{ name: Warehouse.name, schema: WarehouseSchema }])],
  providers: [WarehouseService],
  controllers: [WarehouseController],
  exports: [WarehouseService, MongooseModule],
})
export class WarehousesModule {}
