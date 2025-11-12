import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type StockMovementDocument = StockMovement & Document;

@Schema({ collection: 'stock_movements', timestamps: true })
export class StockMovement {
  @Prop({ type: Types.ObjectId, ref: 'Product', required: true })
  product_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Warehouse', default: null })
  from_warehouse_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'Warehouse', default: null })
  to_warehouse_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  user_id: Types.ObjectId;

  @Prop({ required: true })
  quantity: number;

  @Prop({ required: true, enum: ['transfer', 'purchase', 'adjustment', 'return', 'sale'] })
  movement_type: 'transfer' | 'purchase' | 'adjustment' | 'return' | 'sale';

  @Prop({ type: Date, default: Date.now })
  created_at: Date;

  @Prop({ default: null })
  note: string;

  @Prop({ default: null })
  source_type: string; // e.g., 'sale', 'purchase', 'purchase_return'

  @Prop({ type: Types.ObjectId, default: null })
  source_id: Types.ObjectId; // Link to the source document (sale_id, purchase_id, etc.)
}

export const StockMovementSchema = SchemaFactory.createForClass(StockMovement);
