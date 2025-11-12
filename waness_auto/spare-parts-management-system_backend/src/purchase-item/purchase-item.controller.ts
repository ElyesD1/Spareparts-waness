import { Controller, Get, Post, Body, Param, Delete, Put, UseGuards, Req } from '@nestjs/common';
import { PurchaseItemService } from './purchase-item.service';
import { CreatePurchaseItemDto } from './dto/create-purchase-item.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';

@Controller('purchase-item')
export class PurchaseItemController {
  constructor(private readonly purchaseItemService: PurchaseItemService) {}

    @UseGuards(JwtAuthGuard)
  @Post()
  create(@Body() createPurchaseItemDto: CreatePurchaseItemDto, @Req() req) {
    // Add user_id from the authenticated request
    const userId = req.user?.sub;
    return this.purchaseItemService.create(createPurchaseItemDto, userId);
  }

    @UseGuards(JwtAuthGuard)
  @Get()
  findAll() {
    return this.purchaseItemService.findAll();
  }

  @Get('test/purchase/:purchaseId')
  async testFindByPurchase(@Param('purchaseId') purchaseId: string) {
    try {
      console.log(`Test Controller: Fetching purchase items for purchase ID: ${purchaseId}`);
      const items = await this.purchaseItemService.findByPurchaseId(purchaseId);
      console.log(`Test Controller: Successfully fetched ${items.length} items for purchase ID: ${purchaseId}`);
      return items;
    } catch (error) {
      console.error(`Test Controller: Error fetching purchase items for purchase ID: ${purchaseId}`, error);
      throw error;
    }
  }

  @Get('purchase/:purchaseId')
  async findByPurchase(@Param('purchaseId') purchaseId: string) {
    try {
      console.log(`Controller: Fetching purchase items for purchase ID: ${purchaseId}`);
      const items = await this.purchaseItemService.findByPurchaseId(purchaseId);
      console.log(`Controller: Successfully fetched ${items.length} items for purchase ID: ${purchaseId}`);
      return items;
    } catch (error) {
      console.error(`Controller: Error fetching purchase items for purchase ID: ${purchaseId}`, error);
      throw error;
    }
  }

    @UseGuards(JwtAuthGuard)
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.purchaseItemService.findOne(id);
  }
  
    @UseGuards(JwtAuthGuard)
  @Put(':id')
  update(@Param('id') id: string, @Body() updatePurchaseItemDto: any, @Req() req) {
    const userId = req.user?.sub;
    return this.purchaseItemService.update(id, updatePurchaseItemDto, userId);
  }

    @UseGuards(JwtAuthGuard)
  @Delete(':id')
  remove(@Param('id') id: string, @Req() req) {
    const userId = req.user?.sub;
    return this.purchaseItemService.remove(id, userId);
  }
} 
