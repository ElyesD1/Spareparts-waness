import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SaleDocument = Sale & Document;

@Schema({ collection: 'sales' })
export class Sale {
  @Prop({ type: Types.ObjectId, ref: 'Warehouse', required: true })
  warehouse_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  created_by: Types.ObjectId;

  @Prop({ default: null })
  customer_name: string;

  @Prop({ required: true, type: Date })
  sale_date: Date;

  @Prop({ required: true, type: Number })
  total_amount: number;

  // Link back to a credit sale that generated this sale (idempotency)
  @Prop({ type: String, default: null })
  source_credit_sale_id: string | null;
}

export const SaleSchema = SchemaFactory.createForClass(Sale);
