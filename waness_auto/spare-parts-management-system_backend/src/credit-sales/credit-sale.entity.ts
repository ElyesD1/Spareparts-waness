import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type CreditSaleDocument = CreditSale & Document;

@Schema({ collection: 'credit_sales', timestamps: true })
export class CreditSale {
  @Prop({ type: Types.ObjectId, ref: 'Customer', required: true })
  customer_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Warehouse', required: true })
  warehouse_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  created_by: Types.ObjectId;

  @Prop({ required: true, type: Date })
  sale_date: Date;

  @Prop({ required: true, type: Number })
  total_amount: number;

  @Prop({ required: true, type: Number })
  down_payment: number;

  @Prop({ required: true, type: Number })
  credit_amount: number;

  @Prop({ required: true, type: Number })
  installment_count: number;

  @Prop({ required: true, type: Number })
  monthly_payment: number;

  @Prop({ required: true, type: Date })
  first_payment_date: Date;

  @Prop({ type: Date, default: null })
  last_payment_date: Date;

  @Prop({
    enum: ['pending', 'active', 'completed', 'overdue'],
    default: 'pending'
  })
  status: 'pending' | 'active' | 'completed' | 'overdue';

  @Prop({ default: null })
  notes: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const CreditSaleSchema = SchemaFactory.createForClass(CreditSale); 