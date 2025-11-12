import { Controller, Post, Body, Get, Param, Put, Delete, UseGuards, Req, BadRequestException } from '@nestjs/common';
import { SalesService } from './sales.service';
import { CreateSaleDto } from './dto/create-sale.dto';
import { Sale } from './sale.entity';
import { JwtAuthGuard } from '../auth/jwt.guard';

@Controller('sales')
@UseGuards(JwtAuthGuard)
export class SalesController {
  constructor(private readonly salesService: SalesService) {}

  @Post()
  create(@Body() createSaleDto: CreateSaleDto, @Req() req) {
    const userId = req.user?.sub;
    
    // Additional validation at controller level
    console.log('[SalesController] Received sale data:', createSaleDto);
    console.log('[SalesController] Warehouse ID type:', typeof createSaleDto.warehouse_id);
    console.log('[SalesController] Warehouse ID value:', createSaleDto.warehouse_id);
    console.log('[SalesController] Full request body:', JSON.stringify(createSaleDto, null, 2));
    
    if (!createSaleDto.warehouse_id || createSaleDto.warehouse_id === null || createSaleDto.warehouse_id === undefined) {
      console.error('[SalesController] ERROR: warehouse_id is missing or null');
      console.error('[SalesController] Full DTO:', createSaleDto);
      throw new BadRequestException('warehouse_id is required and cannot be null. Please select a warehouse.');
    }
    
    if (typeof createSaleDto.warehouse_id !== 'string') {
      console.error('[SalesController] ERROR: warehouse_id is not a valid string');
      console.error('[SalesController] warehouse_id value:', createSaleDto.warehouse_id);
      throw new BadRequestException(`warehouse_id must be a valid string. Received: ${createSaleDto.warehouse_id}`);
    }
    
    console.log('[SalesController] Validation passed, calling service...');
    return this.salesService.create(createSaleDto, userId);
  }

  @Get()
  async findAll() {
    return this.salesService.findAll();
  }

  @Get('products/:warehouseId')
  async getProductsByWarehouse(@Param('warehouseId') warehouseId: string) {
    return this.salesService.getProductsByWarehouse(warehouseId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.salesService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateSaleDto: Partial<Sale>) {
    return this.salesService.update(id, updateSaleDto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.salesService.remove(id);
  }
} 


