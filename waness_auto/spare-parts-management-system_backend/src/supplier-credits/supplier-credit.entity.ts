import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum CreditSourceType {
  PURCHASE_RETURN = 'purchase_return',
  MANUAL_ADJUSTMENT = 'manual_adjustment'
}

export enum CreditStatus {
  ACTIVE = 'active',
  EXPIRED = 'expired',
  USED = 'used'
}

export type SupplierCreditDocument = SupplierCredit & Document;

@Schema({ collection: 'supplier_credits', timestamps: true })
export class SupplierCredit {
  @Prop({ type: Types.ObjectId, ref: 'Supplier', required: true })
  supplier_id: Types.ObjectId;

  @Prop({ required: true, type: Number })
  credit_amount: number;

  @Prop({ required: true, type: Number })
  remaining_amount: number;

  @Prop({
    required: true,
    enum: CreditSourceType
  })
  source_type: CreditSourceType;

  @Prop({ default: null, type: String })
  source_id: string;

  @Prop({ type: Date, default: null })
  expiry_date: Date;

  @Prop({
    enum: CreditStatus,
    default: CreditStatus.ACTIVE
  })
  status: CreditStatus;

  @Prop({ default: null })
  notes: string;

  created_at?: Date;
  updated_at?: Date;
}

export const SupplierCreditSchema = SchemaFactory.createForClass(SupplierCredit); 