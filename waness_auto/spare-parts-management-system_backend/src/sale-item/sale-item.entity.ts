import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SaleItemDocument = SaleItem & Document;

@Schema({ collection: 'sale_items' })
export class SaleItem {
  @Prop({ type: Types.ObjectId, ref: 'Sale', required: true })
  sale_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Product', required: true })
  product_id: Types.ObjectId;

  @Prop({ required: true })
  quantity: number;

  @Prop({ required: true, type: Number })
  unit_price: number;
}

export const SaleItemSchema = SchemaFactory.createForClass(SaleItem);
