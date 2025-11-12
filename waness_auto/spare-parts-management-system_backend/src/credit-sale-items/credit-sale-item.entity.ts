import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type CreditSaleItemDocument = CreditSaleItem & Document;

@Schema({ collection: 'credit_sale_items' })
export class CreditSaleItem {
  @Prop({ type: Types.ObjectId, ref: 'CreditSale', required: true })
  credit_sale_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Product', required: true })
  product_id: Types.ObjectId;

  @Prop({ required: true, type: Number })
  quantity: number;

  @Prop({ required: true, type: Number })
  unit_price: number;

  @Prop({ required: true, type: Number })
  total_price: number;
}

export const CreditSaleItemSchema = SchemaFactory.createForClass(CreditSaleItem);