import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Put,
  Delete,
  UseInterceptors,
  UploadedFile,
  Query
} from "@nestjs/common";
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { ProductsService } from "./products.service";
import { CreateProductDto } from "./dto/create-product.dto";
import { UpdateProductDto } from "./dto/update-product.dto";

@Controller('products')
export class ProductsController {
  constructor(private readonly service: ProductsService) {}

  @Post()
  create(@Body() data: CreateProductDto) {
    return this.service.create(data);
  }

  @Post('with-image')
  @UseInterceptors(FileInterceptor('image', {
    storage: diskStorage({
      destination: './uploads',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, uniqueSuffix + extname(file.originalname));
      },
    }),
  }))
  async createWithImage(
    @Body('product') product: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    const data = JSON.parse(product);
    data.image = file.filename;
    return this.service.create(data);
  }

  @Get()
  async findAll(@Query('includeDeleted') includeDeleted?: string): Promise<any[]> {
    const products = await this.service.findAll(includeDeleted === 'true');
    return products.map(product => ({
      ...product,
      image: product.image ? `${process.env.HOST_URL || 'http://localhost:3000'}/uploads/${product.image}` : null,
    }));
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @Get('barcode/:barcode')
  findByBarcode(@Param('barcode') barcode: string) {
    return this.service.findByBarcode(barcode);
  }

  @Get('by-warehouse/:warehouseId')
  findByWarehouse(@Param('warehouseId') warehouseId: string) {
    return this.service.findByWarehouse(warehouseId);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() data: any) {
    return this.service.update(id, data);
  }

  @Put(':id/with-image')
  @UseInterceptors(FileInterceptor('image', {
    storage: diskStorage({
      destination: './uploads',
      filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        cb(null, uniqueSuffix + extname(file.originalname));
      },
    }),
  }))
  async updateWithImage(
    @Param('id') id: string,
    @Body('product') product: string,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    const data = JSON.parse(product);
    if (file) data.image = file.filename;
    return this.service.update(id, data);
  }

  @Delete(':id')
  async remove(@Param('id') id: string, @Query('force') force?: boolean) {
    if (force === true) {
      return this.service.remove(id, true);
    } else {
      return this.service.softDelete(id);
    }
  }

  @Put(':id/restore')
  restore(@Param('id') id: string) {
    return this.service.restore(id);
  }
}

