import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User, UserDocument } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
  ) {}

  async create(userData: Partial<User>) {
    const user = new this.userModel(userData);
    return user.save();
  }

  findAll() {
    return this.userModel.find().populate('warehouse_id').exec();
  }

  findByEmail(email: string) {
    return this.userModel.findOne({ email }).exec();
  }

  findById(id: string) {
    return this.userModel.findById(id).exec();
  }

  findByIdWithWarehouse(id: string) {
    return this.userModel.findById(id).populate('warehouse_id').exec();
  }

  async update(id: string, attrs: Partial<User>) {
    console.log('Update user', id, attrs);
    const result = await this.userModel
      .findByIdAndUpdate(id, attrs, { new: true })
      .populate('warehouse_id')
      .exec();
    console.log('Résultat update MongoDB:', result);
    return result;
  }

  async deleteUser(id: string): Promise<{ success: boolean; message: string }> {
    try {
      // Check if user exists
      const user = await this.findById(id);
      if (!user) {
        return { success: false, message: 'User not found' };
      }

      // Check if user has active relationships (sales, purchases, etc.)
      const hasActiveRelationships = await this.checkUserRelationships(id);
      if (hasActiveRelationships) {
        return { 
          success: false, 
          message: 'Cannot delete user. User has active relationships with sales, purchases, or other data.' 
        };
      }

      // Delete the user
      await this.userModel.findByIdAndDelete(id).exec();

      return { 
        success: true, 
        message: 'User deleted successfully' 
      };
    } catch (error) {
      console.error('Error deleting user:', error);
      return { 
        success: false, 
        message: 'Error deleting user' 
      };
    }
  }

  private async checkUserRelationships(userId: string): Promise<boolean> {
    try {
      const userObjectId = new Types.ObjectId(userId);

      // Check for sales created by this user
      const salesCount = await this.userModel.db.collection('sales')
        .countDocuments({ created_by: userObjectId });

      // Check for purchases created by this user
      const purchasesCount = await this.userModel.db.collection('purchases')
        .countDocuments({ created_by: userObjectId });

      // Check for stock movements by this user
      const movementsCount = await this.userModel.db.collection('stock_movements')
        .countDocuments({ user_id: userObjectId });

      // If any relationships exist, return true
      return salesCount > 0 || purchasesCount > 0 || movementsCount > 0;
    } catch (error) {
      console.error('Error checking user relationships:', error);
      return true; // Assume relationships exist if we can't check
    }
  }
}

