import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type CreditPaymentDocument = CreditPayment & Document;

@Schema({ collection: 'credit_payments', timestamps: true })
export class CreditPayment {
  @Prop({ type: Types.ObjectId, ref: 'CreditSale', required: true })
  credit_sale_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  received_by: Types.ObjectId;

  @Prop({ required: true, type: Number })
  amount: number;

  @Prop({ required: true, type: Date })
  payment_date: Date;

  @Prop({
    enum: ['cash', 'check', 'bank_transfer'],
    default: 'cash'
  })
  payment_method: 'cash' | 'check' | 'bank_transfer';

  @Prop({ default: null })
  reference_number: string;

  @Prop({ default: null })
  notes: string;

  createdAt?: Date;
}

export const CreditPaymentSchema = SchemaFactory.createForClass(CreditPayment);
