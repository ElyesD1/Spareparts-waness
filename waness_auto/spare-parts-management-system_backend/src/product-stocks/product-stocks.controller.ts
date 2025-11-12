import { Controller, Post, Body, Get, Param, ParseIntPipe, Put, Delete } from "@nestjs/common";
import { CreateProductStockDto } from "./dto/create-product-stock.dto";
import { UpdateProductStockDto } from "./dto/update-product-stock.dto";
import { ProductStocksService } from "./product-stocks.service";

@Controller('product-stocks')
export class ProductStocksController {
  constructor(private svc: ProductStocksService) {}

  @Post() create(@Body() dto: CreateProductStockDto) {
    return this.svc.create(dto);
  }

  @Get() findAll() {
    return this.svc.findAll();
  }

  // List all products and quantities for a specific warehouse
  @Get('by-warehouse/:warehouseId')
  async findByWarehouse(@Param('warehouseId') warehouseId: string) {
    const all = await this.svc.findAll();
    return all.filter((s) => s.warehouse_id.toString() === warehouseId);
  }

  @Get(':id') findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Get('check-availability/:productId/:warehouseId/:quantity')
  async checkAvailability(
    @Param('productId') productId: string,
    @Param('warehouseId') warehouseId: string,
    @Param('quantity', ParseIntPipe) quantity: number,
  ) {
    return this.svc.checkStockAvailability(productId, warehouseId, quantity);
  }

  @Get('stock-level/:productId/:warehouseId')
  async getStockLevel(
    @Param('productId') productId: string,
    @Param('warehouseId') warehouseId: string,
  ) {
    const stockLevel = await this.svc.getStockLevel(productId, warehouseId);
    return { stockLevel };
  }

  @Put('update-stock')
  async updateStock(@Body() dto: { product_id: string; warehouse_id: string; quantity: number }) {
    return this.svc.update(dto.product_id, { quantity: dto.quantity });
  }

  // @Put(':id')
  // update(@Param('id', ParseIntPipe) id: number, @Body() dto: UpdateProductStockDto) {
  //   return this.svc.update(id, dto);
  // }

  // @Delete(':id')
  // remove(@Param('id', ParseIntPipe) id: number) {
  //   return this.svc.remove(id);
  // }
}

