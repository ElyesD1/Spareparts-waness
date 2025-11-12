import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type OperationalExpenseDocument = OperationalExpense & Document;

@Schema({ collection: 'operational_expenses' })
export class OperationalExpense {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true, type: Number })
  amount: number;

  @Prop({ required: true, enum: ['rent', 'electricity', 'water', 'fuel', 'other'] })
  type: 'rent' | 'electricity' | 'water' | 'fuel' | 'other';

  @Prop({ type: Types.ObjectId, ref: 'Warehouse', required: true })
  warehouse_id: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  created_by: Types.ObjectId;

  @Prop({ required: true })
  date: string;

  @Prop({ default: null })
  note: string;
}

export const OperationalExpenseSchema = SchemaFactory.createForClass(OperationalExpense);
