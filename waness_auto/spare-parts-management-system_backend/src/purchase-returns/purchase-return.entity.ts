import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum ReturnStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  COMPLETED = 'completed',
}

export type PurchaseReturnDocument = PurchaseReturn & Document;

@Schema({ collection: 'purchase_returns', timestamps: true })
export class PurchaseReturn {
  /** Supplier */
  @Prop({ type: Types.ObjectId, ref: 'Supplier', required: true })
  supplier_id: Types.ObjectId;

  /** Warehouse */
  @Prop({ type: Types.ObjectId, ref: 'Warehouse', required: true })
  warehouse_id: Types.ObjectId;

  /** Created By */
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  created_by: Types.ObjectId;

  /** Return Date */
  @Prop({ required: true, type: Date })
  return_date: Date;

  /** Total Amount */
  @Prop({ required: true, type: Number })
  total_amount: number;

  /** Reason */
  @Prop({ required: true })
  reason: string;

  /** Status */
  @Prop({
    enum: ReturnStatus,
    default: ReturnStatus.PENDING,
  })
  status: ReturnStatus;

  /** Optional Notes */
  @Prop({ default: null })
  notes?: string;

  /** Approved By */
  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  approved_by?: Types.ObjectId;

  /** Approved At */
  @Prop({ type: Date, default: null })
  approved_at?: Date;

  created_at?: Date;
  updated_at?: Date;
}

export const PurchaseReturnSchema = SchemaFactory.createForClass(PurchaseReturn);
