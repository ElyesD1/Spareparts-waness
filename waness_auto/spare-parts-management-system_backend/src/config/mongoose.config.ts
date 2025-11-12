import { MongooseModuleOptions } from '@nestjs/mongoose';

export const mongooseConfig: MongooseModuleOptions & { uri: string } = {
  uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/spare_parts_management',
  // Additional options
  retryWrites: true,
  w: 'majority',
};
