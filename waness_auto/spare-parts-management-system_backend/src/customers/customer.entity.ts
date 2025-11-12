import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type CustomerDocument = Customer & Document;

@Schema({ collection: 'customers', timestamps: true })
export class Customer {
  @Prop({ required: true })
  name: string;

  @Prop({ unique: true, default: null })
  email: string;

  @Prop({ required: true })
  phone_number: string;

  @Prop({ default: null })
  address: string;

  @Prop({ default: null })
  company_name: string;

  @Prop({ default: null })
  tax_number: string;

  // National Identity number (CIN)
  @Prop({ type: Number, unique: true, sparse: true, default: null })
  cin: number;

  @Prop({ type: Number, default: 0 })
  credit_limit: number;

  @Prop({ type: Number, default: 0 })
  current_balance: number;

  @Prop({ default: true })
  is_active: boolean;

  createdAt?: Date;
  updatedAt?: Date;
}

export const CustomerSchema = SchemaFactory.createForClass(Customer);