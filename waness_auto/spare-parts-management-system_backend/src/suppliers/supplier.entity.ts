import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type SupplierDocument = Supplier & Document;

@Schema({ collection: 'suppliers' })
export class Supplier {
  @Prop({ required: true })
  name: string;

  @Prop({ default: null })
  contact_info: string;

  @Prop({ default: null })
  address: string;
}

export const SupplierSchema = SchemaFactory.createForClass(Supplier);
