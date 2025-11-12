import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type SupplierCreditUsageDocument = SupplierCreditUsage & Document;

@Schema({ collection: 'supplier_credit_usage', timestamps: true })
export class SupplierCreditUsage {
  @Prop({ type: Types.ObjectId, ref: 'SupplierCredit', required: true })
  supplier_credit_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Purchase', required: true })
  purchase_id: Types.ObjectId;

  @Prop({ required: true, type: Number })
  amount_used: number;

  used_at?: Date;
}

export const SupplierCreditUsageSchema = SchemaFactory.createForClass(SupplierCreditUsage); 