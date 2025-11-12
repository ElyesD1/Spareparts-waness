import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type PurchaseReturnItemDocument = PurchaseReturnItem & Document;

@Schema({ collection: 'purchase_return_items' })
export class PurchaseReturnItem {
  /** FK vers PurchaseReturn */
  @Prop({ type: Types.ObjectId, ref: 'PurchaseReturn', required: true })
  purchase_return_id: Types.ObjectId;

  /** FK vers Product */
  @Prop({ type: Types.ObjectId, ref: 'Product', required: true })
  product_id: Types.ObjectId;

  /** Quantité retournée */
  @Prop({ required: true, type: Number })
  quantity: number;

  /** Prix unitaire */
  @Prop({ required: true, type: Number })
  unit_price: number;

  /** Prix total */
  @Prop({ required: true, type: Number })
  total_price: number;
}

export const PurchaseReturnItemSchema = SchemaFactory.createForClass(PurchaseReturnItem);
