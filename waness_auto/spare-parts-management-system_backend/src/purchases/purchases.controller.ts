import { Controller, Get, Post, Body, Param, Delete, Put } from '@nestjs/common';
import { PurchasesService } from './purchases.service';
import { CreatePurchaseDto } from './dto/create-purchase.dto';

@Controller('purchases')
export class PurchasesController {
  constructor(private readonly purchasesService: PurchasesService) {}

  @Post()
  create(@Body() createPurchaseDto: CreatePurchaseDto) {
    return this.purchasesService.create(createPurchaseDto);
  }

  @Get()
  findAll() {
    return this.purchasesService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.purchasesService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updatePurchaseDto: any) {
    return this.purchasesService.update(id, updatePurchaseDto);
  }

  @Put(':id/deliver')
  async deliver(@Param('id') id: string, @Body() body: { deliveredBy: string }) {
    return this.purchasesService.deliver(id, body.deliveredBy);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.purchasesService.remove(id);
  }
} 

