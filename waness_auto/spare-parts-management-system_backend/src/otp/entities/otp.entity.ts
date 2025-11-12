import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type OtpDocument = Otp & Document;

@Schema({ collection: 'otp', timestamps: true })
export class Otp {
  @Prop({ required: true })
  otp: string; // hashé

  @Prop({ type: Types.ObjectId, ref: 'User', default: null })
  userId: Types.ObjectId;

  @Prop({ required: true, type: Date })
  otpExpires: Date;

  createdAt?: Date;
}

export const OtpSchema = SchemaFactory.createForClass(Otp); 