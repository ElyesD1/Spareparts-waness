import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Warehouse, WarehouseDocument } from './entities/warehouse.entity';

@Injectable()
export class WarehouseService {
  constructor(
    @InjectModel(Warehouse.name)
    private warehouseModel: Model<WarehouseDocument>,
  ) {}

  create(data: Partial<Warehouse>) {
    const warehouse = new this.warehouseModel(data);
    return warehouse.save();
  }

  findAll() {
    return this.warehouseModel.find().exec();
  }

  findOne(id: string) {
    return this.warehouseModel.findById(id).exec();
  }

  async remove(id: string) {
    try {
      // Check if warehouse exists
      const warehouse = await this.findOne(id);
      if (!warehouse) {
        throw new Error('Warehouse not found');
      }

      const warehouseObjectId = new Types.ObjectId(id);

      // Check if warehouse has any associated users
      const usersCount = await this.warehouseModel.db.collection('users')
        .countDocuments({ warehouse_id: warehouseObjectId });

      if (usersCount > 0) {
        throw new Error('Cannot delete warehouse: Warehouse has associated users. Please reassign users first.');
      }

      // Check if warehouse has any stock records
      const stockCount = await this.warehouseModel.db.collection('product_stocks')
        .countDocuments({ warehouse_id: warehouseObjectId });

      if (stockCount > 0) {
        throw new Error('Cannot delete warehouse: Warehouse has stock records. Please remove all stock entries first.');
      }

      // Check if warehouse has any sales
      const salesCount = await this.warehouseModel.db.collection('sales')
        .countDocuments({ warehouse_id: warehouseObjectId });

      if (salesCount > 0) {
        throw new Error('Cannot delete warehouse: Warehouse has sales records. Please remove sales first.');
      }

      // Check if warehouse has any purchase items (warehouse_id in purchase_items)
      const purchaseItemsCount = await this.warehouseModel.db.collection('purchase_items')
        .countDocuments({ warehouse_id: warehouseObjectId });

      if (purchaseItemsCount > 0) {
        throw new Error('Cannot delete warehouse: Warehouse has purchase records. Please remove purchases first.');
      }

      return this.warehouseModel.findByIdAndDelete(id).exec();
    } catch (error) {
      throw error;
    }
  }

  async update(id: string, data: Partial<Warehouse>) {
    try {
      return this.warehouseModel
        .findByIdAndUpdate(id, data, { new: true })
        .exec();
    } catch (error) {
      throw error;
    }
  }
}
