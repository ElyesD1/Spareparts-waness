import { Controller, Get, Post, Body, Param, Delete, Put } from '@nestjs/common';
import { StockMovementService } from './stock-movement.service';
import { CreateStockMovementDto } from './dto/create-stock-movement.dto';
import { UpdateStockMovementDto } from './dto/update-stock-movement.dto';
import { StockMovementModule } from '../stock-movement/stock-movement.module';

@Controller('movements')
export class StockMovementController {
  constructor(private readonly stockMovementService: StockMovementService) {}

  @Post()
  create(@Body() createStockMovementDto: CreateStockMovementDto) {
    console.log('Creating StockMovement:', createStockMovementDto);
    return this.stockMovementService.create(createStockMovementDto);
  }

  @Get()
  findAll() {
    return this.stockMovementService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.stockMovementService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateStockMovementDto: UpdateStockMovementDto) {
    return this.stockMovementService.update(id, updateStockMovementDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.stockMovementService.remove(id);
  }
} 
 

