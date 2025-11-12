import { Controller, Get, Post, Body, Param, Put, Delete } from '@nestjs/common';
import { WarehouseService } from './warehouse.service';

@Controller('warehouses')
export class WarehouseController {
  constructor(private service: WarehouseService) {}

  @Post()
  create(@Body() data: { name: string; location: string }) {
    return this.service.create(data);
  }

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() data: { name?: string; location?: string }) {
    return this.service.update(id, data);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.service.remove(id);
  }
}

