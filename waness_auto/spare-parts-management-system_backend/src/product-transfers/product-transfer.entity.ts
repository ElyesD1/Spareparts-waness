import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export enum TransferPriority {
  LOW = 'low',
  NORMAL = 'normal',
  HIGH = 'high',
  URGENT = 'urgent',
}

export enum TransferStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  IN_TRANSIT = 'in_transit',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
}

export type ProductTransferDocument = ProductTransfer & Document;

@Schema({ collection: 'product_transfers', timestamps: true })
export class ProductTransfer {
  @Prop({ type: Types.ObjectId, ref: 'Product', required: true })
  product_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Warehouse', required: true })
  from_warehouse_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Warehouse', required: true })
  to_warehouse_id: Types.ObjectId;

  @Prop({ required: true })
  quantity: number;

  @Prop({
    enum: TransferPriority,
    default: TransferPriority.NORMAL,
  })
  priority: TransferPriority;

  @Prop({
    enum: TransferStatus,
    default: TransferStatus.PENDING,
  })
  status: TransferStatus;

  @Prop({ required: true })
  reason: string;

  @Prop({ default: null })
  notes: string;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  requested_by: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  approved_by: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  processed_by: Types.ObjectId;

  created_at?: Date;
  updated_at?: Date;

  @Prop({ type: Date, default: null })
  approved_at: Date;

  @Prop({ type: Date, default: null })
  processed_at: Date;
}

export const ProductTransferSchema = SchemaFactory.createForClass(ProductTransfer);
