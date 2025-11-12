import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type PurchaseItemDocument = PurchaseItem & Document;

@Schema({ collection: 'purchase_items' })
export class PurchaseItem {
  @Prop({ type: Types.ObjectId, ref: 'Purchase', required: true })
  purchase_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Product', required: true })
  product_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Warehouse', required: true })
  warehouse_id: Types.ObjectId;

  @Prop({ required: true })
  quantity: number;

  @Prop({ required: true, type: Number })
  unit_price: number;
}

export const PurchaseItemSchema = SchemaFactory.createForClass(PurchaseItem);
