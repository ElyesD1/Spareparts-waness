import { Controller, Get, Post, Body, Param, Delete, Put, UseGuards, Req } from '@nestjs/common';
import { SaleItemService } from './sale-item.service';
import { CreateSaleItemDto } from './dto/create-sale-item.dto';
import { UpdateSaleItemDto } from './dto/update-sale-item.dto';
import { BadRequestException } from '@nestjs/common';
import { join } from 'path';
import { log } from 'console';
import { JwtAuthGuard } from '../auth/jwt.guard';

@Controller('sale-item')
@UseGuards(JwtAuthGuard)
export class SaleItemController {
  constructor(private readonly saleItemService: SaleItemService) {}

  @Post()
  async create(@Body() createSaleItemDto: CreateSaleItemDto, @Req() req) {
    console.log('[SaleItemController] req.user:', req.user);
    let userId = req.user?.sub || req.user?.userId;
    
    // Fallback: get user ID from the sale's created_by field
    if (!userId) {
      console.log('[SaleItemController] No userId in req.user, fetching from sale');
      const saleModel = this.saleItemService['connection'].model('Sale');
      const sale = await saleModel.findById(createSaleItemDto.sale_id).exec();
      if (sale && sale.created_by) {
        userId = sale.created_by.toString();
        console.log('[SaleItemController] Using userId from sale.created_by:', userId);
      }
    }
    
    if (!userId) {
      throw new BadRequestException('User ID not found. Please ensure sale has created_by field.');
    }
    console.log('[SaleItemController] Using userId:', userId);
    return this.saleItemService.create(createSaleItemDto, userId);
  }

  @Get()
  findAll() {
    console.log('[SaleItemController] Finding all sale items');
    return this.saleItemService.findAll();
  }
  
  @Get('sale/:saleId')
  findBySaleId(@Param('saleId') saleId: string) {
    console.log('[SaleItemController] Finding sale items for sale ID:', saleId);
    return this.saleItemService.findBySaleId(saleId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    console.log('[SaleItemController] Finding sale item with ID:', id);
    return this.saleItemService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateSaleItemDto: UpdateSaleItemDto, @Req() req) {
    const userId = req.user?.sub;
    return this.saleItemService.update(id, updateSaleItemDto, userId);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Req() req) {
    const userId = req.user?.sub;
    return this.saleItemService.remove(id, userId);
  }
} 

