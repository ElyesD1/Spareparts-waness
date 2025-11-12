import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type UserDocument = User & Document;

@Schema({ collection: 'users', timestamps: true })
export class User {
  @Prop({ required: true })
  name: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  password_hash: string;

  @Prop({ required: true, unique: true })
  phone_number: number;

  @Prop({
    required: true,
    enum: ['admin', 'manager', 'cashier', 'guest'],
    default: 'cashier'
  })
  role: 'admin' | 'manager' | 'cashier' | 'guest';

  @Prop({ type: Types.ObjectId, ref: 'Warehouse', default: null })
  warehouse_id: Types.ObjectId;

  createdAt?: Date;
  updatedAt?: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);
