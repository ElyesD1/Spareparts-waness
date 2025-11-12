import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type PurchaseDocument = Purchase & Document;

@Schema({ collection: 'purchases' })
export class Purchase {
  @Prop({ type: Types.ObjectId, ref: 'Supplier', default: null })
  supplier_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  created_by: Types.ObjectId;

  @Prop({ required: true, type: Date })
  date: Date;

  @Prop({ required: true, type: Number })
  total_amount: number;

  @Prop({ default: 'pending' })
  status: string; // 'pending' or 'delivered'

  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  delivered_by: Types.ObjectId;

  @Prop({ type: Date, default: null })
  deliveredAt: Date;

  @Prop({ type: Number, default: 0.00 })
  credit_applied: number;

  @Prop({ type: Number, default: null })
  final_amount: number;
}

export const PurchaseSchema = SchemaFactory.createForClass(Purchase);
