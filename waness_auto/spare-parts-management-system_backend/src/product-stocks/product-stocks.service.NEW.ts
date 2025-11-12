import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { ProductStock, ProductStockDocument } from './product-stock.entity';
import { CreateProductStockDto } from './dto/create-product-stock.dto';
import { UpdateProductStockDto } from './dto/update-product-stock.dto';

@Injectable()
export class ProductStocksService {
  reduceStock(product_id: string, id: string, quantity: number) {
    throw new Error('Method not implemented.');
  }
  
  constructor(
    @InjectModel(ProductStock.name) private model: Model<ProductStockDocument>
  ) {}

  async create(dto: CreateProductStockDto) {
    const created = new this.model(dto);
    return created.save();
  }

  async findAll() {
    return this.model.find()
      .populate('product')
      .populate('warehouse')
      .exec();
  }

  async findOne(id: string) {
    return this.model.findById(id)
      .populate('product')
      .populate('warehouse')
      .exec();
  }

  async update(id: string, dto: UpdateProductStockDto) {
    const updated = await this.model.findByIdAndUpdate(id, dto, { new: true }).exec();
    return this.findOne(id);
  }

  async remove(id: string) {
    return this.model.findByIdAndDelete(id).exec();
  }

  async incrementStock(product_id: string, warehouse_id: string, quantity: number) {
    let stock = await this.model.findOne({ 
      product_id: new Types.ObjectId(product_id), 
      warehouse_id: new Types.ObjectId(warehouse_id) 
    }).exec();
    
    if (!stock) {
      stock = new this.model({ 
        product_id: new Types.ObjectId(product_id), 
        warehouse_id: new Types.ObjectId(warehouse_id), 
        quantity: 0 
      });
    }
    
    stock.quantity += quantity;
    return stock.save();
  }

  async getStockLevel(product_id: string, warehouse_id: string) {
    const stock = await this.model.findOne({ 
      product_id: new Types.ObjectId(product_id), 
      warehouse_id: new Types.ObjectId(warehouse_id) 
    })
      .populate('product')
      .populate('warehouse')
      .exec();
    
    return stock ? stock.quantity : 0;
  }

  async checkStockAvailability(product_id: string, warehouse_id: string, quantity: number) {
    const stock = await this.model.findOne({ 
      product_id: new Types.ObjectId(product_id), 
      warehouse_id: new Types.ObjectId(warehouse_id) 
    }).exec();
    
    if (!stock) {
      return {
        available: false,
        currentStock: 0,
        requested: quantity,
        message: `No stock record found for product ${product_id} in warehouse ${warehouse_id}`
      };
    }
    
    if (stock.quantity < quantity) {
      return {
        available: false,
        currentStock: stock.quantity,
        requested: quantity,
        message: `Insufficient stock. Available: ${stock.quantity}, Requested: ${quantity}`
      };
    }
    
    return {
      available: true,
      currentStock: stock.quantity,
      requested: quantity,
      message: 'Stock available'
    };
  }

  async decrementStock(product_id: string, warehouse_id: string, quantity: number) {
    const stock = await this.model.findOne({ 
      product_id: new Types.ObjectId(product_id), 
      warehouse_id: new Types.ObjectId(warehouse_id) 
    }).exec();
    
    if (!stock) {
      throw new Error(`No stock record found for product ${product_id} in warehouse ${warehouse_id}`);
    }
    
    if (stock.quantity < quantity) {
      throw new Error(`Insufficient stock. Available: ${stock.quantity}, Requested: ${quantity} for product ${product_id} in warehouse ${warehouse_id}`);
    }
    
    stock.quantity -= quantity;
    return stock.save();
  }

  async decrementStockForReturn(product_id: string, warehouse_id: string, quantity: number) {
    const stock = await this.model.findOne({ 
      product_id: new Types.ObjectId(product_id), 
      warehouse_id: new Types.ObjectId(warehouse_id) 
    }).exec();
    
    if (!stock) {
      // For returns, create a stock record with negative quantity if none exists
      const newStock = new this.model({ 
        product_id: new Types.ObjectId(product_id), 
        warehouse_id: new Types.ObjectId(warehouse_id), 
        quantity: -quantity 
      });
      return newStock.save();
    }
    
    // For returns, allow going negative (items being returned that may have been moved elsewhere)
    stock.quantity -= quantity;
    return stock.save();
  }
}
