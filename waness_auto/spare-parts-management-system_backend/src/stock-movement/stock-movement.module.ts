import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { StockMovementController } from './stock-movement.controller';
import { StockMovementService } from './stock-movement.service';
import { StockMovement, StockMovementSchema } from './stock-movement.entity';

@Module({
  imports: [MongooseModule.forFeature([{ name: StockMovement.name, schema: StockMovementSchema }])],
  controllers: [StockMovementController],
  providers: [StockMovementService],
  exports: [StockMovementService, MongooseModule],
})
export class StockMovementModule {}
