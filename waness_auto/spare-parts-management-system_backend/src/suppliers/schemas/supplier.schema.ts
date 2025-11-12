import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Supplier extends Document {
  @Prop({ required: true })
  name: string;

  @Prop()
  contact_info: string;

  @Prop()
  address: string;
}

export const SupplierSchema = SchemaFactory.createForClass(Supplier);

// Add indexes
SupplierSchema.index({ name: 1 });
