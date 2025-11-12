import { Controller, Get, Post, Body, Param, Delete, Put, UseGuards, Req, Query } from '@nestjs/common';
import { PurchaseReturnsService } from './purchase-returns.service';
import { CreatePurchaseReturnDto } from './dto/create-purchase-return.dto';
import { UpdatePurchaseReturnDto } from './dto/update-purchase-return.dto';
import { JwtAuthGuard } from '../auth/jwt.guard';
import { ReturnStatus } from './purchase-return.entity';

@Controller('purchase-returns')
@UseGuards(JwtAuthGuard)
export class PurchaseReturnsController {
  constructor(private readonly purchaseReturnsService: PurchaseReturnsService) {}

  @Post()
  create(@Body() createPurchaseReturnDto: CreatePurchaseReturnDto, @Req() req) {
    const userId = req.user.sub;
    return this.purchaseReturnsService.create(createPurchaseReturnDto, userId);
  }

  @Get()
  findAll(@Query('supplier_id') supplierId?: string) {
    if (supplierId) {
      return this.purchaseReturnsService.findBySupplier(supplierId);
    }
    return this.purchaseReturnsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.purchaseReturnsService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updatePurchaseReturnDto: UpdatePurchaseReturnDto) {
    return this.purchaseReturnsService.update(id, updatePurchaseReturnDto);
  }

  @Put(':id/approve')
  approve(@Param('id') id: string, @Req() req) {
    const userId = req.user.sub;
    return this.purchaseReturnsService.approve(id, userId);
  }

  @Put(':id/reject')
  reject(@Param('id') id: string, @Body() body: { reason: string }, @Req() req) {
    const userId = req.user.sub;
    return this.purchaseReturnsService.reject(id, userId, body.reason);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.purchaseReturnsService.remove(id);
  }
} 

