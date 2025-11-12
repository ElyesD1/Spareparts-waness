import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type ProductStockDocument = ProductStock & Document;

@Schema({ collection: 'product_stocks' })
export class ProductStock {
  @Prop({ type: Types.ObjectId, ref: 'Product', required: true })
  product_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Warehouse', required: true })
  warehouse_id: Types.ObjectId;

  @Prop({ required: true })
  quantity: number;
}

export const ProductStockSchema = SchemaFactory.createForClass(ProductStock);
