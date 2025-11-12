import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProductsController } from './products.controller';
import { Product, ProductSchema } from './products.entity';
import { ProductsService } from './products.service';

@Module({
  imports: [MongooseModule.forFeature([{ name: Product.name, schema: ProductSchema }])],
  providers: [ProductsService],
  controllers: [ProductsController],
  exports: [MongooseModule],
})
export class ProductsModule {}
