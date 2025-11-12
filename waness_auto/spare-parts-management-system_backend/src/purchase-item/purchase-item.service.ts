import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CreatePurchaseItemDto } from './dto/create-purchase-item.dto';
import { PurchaseItem, PurchaseItemDocument } from './purchase-item.entity';
import { ProductStocksService } from '../product-stocks/product-stocks.service';
import { StockMovementService } from '../stock-movement/stock-movement.service';
import { MovementType } from '../stock-movement/dto/create-stock-movement.dto';

@Injectable()
export class PurchaseItemService {
  constructor(
    @InjectModel(PurchaseItem.name)
    private readonly purchaseItemModel: Model<PurchaseItemDocument>,
    private readonly productStocksService: ProductStocksService,
    private readonly stockMovementService: StockMovementService,
  ) {}

  async create(createPurchaseItemDto: CreatePurchaseItemDto, userId: string): Promise<PurchaseItem> {
    console.log('Création item:', createPurchaseItemDto);
    
    const item = new this.purchaseItemModel({
      ...createPurchaseItemDto,
      purchase_id: new Types.ObjectId(createPurchaseItemDto.purchase_id as any),
      product_id: new Types.ObjectId(createPurchaseItemDto.product_id as any),
      warehouse_id: new Types.ObjectId(createPurchaseItemDto.warehouse_id as any),
    });
    
    const saved = await item.save();
    
    // REMOVED: Automatic stock addition - this will only happen when purchase is delivered
    
    return saved.toObject();
  }

  async findAll(): Promise<PurchaseItem[]> {
    return this.purchaseItemModel.find()
      .populate('product_id')
      .populate('warehouse_id')
      .populate('purchase_id')
      .exec();
  }

  async findOne(id: string): Promise<PurchaseItem | null> {
    return this.purchaseItemModel.findById(id)
      .populate('product_id')
      .populate('warehouse_id')
      .populate('purchase_id')
      .exec();
  }

  async update(id: string, updatePurchaseItemDto: Partial<PurchaseItem>, userId: string): Promise<PurchaseItem | null> {
    const old = await this.findOne(id);
    await this.purchaseItemModel.findByIdAndUpdate(id, updatePurchaseItemDto, { new: true }).exec();
    const updated = await this.findOne(id);
    
    // REMOVED: Stock manipulation - this will only happen when purchase is delivered
    
    return updated;
  }

  async remove(id: string, userId: string): Promise<{ deleted: boolean }> {
    const item = await this.findOne(id);
    const result = await this.purchaseItemModel.findByIdAndDelete(id).exec();
    
    // REMOVED: Stock manipulation - this will only happen when purchase is delivered
    
    return { deleted: !!result };
  }

  async findByPurchaseId(purchaseId: string | number): Promise<PurchaseItem[]> {
    try {
      console.log(`Fetching purchase items for purchase ID: ${purchaseId}`);
      const objectId = typeof purchaseId === 'string' ? new Types.ObjectId(purchaseId) : new Types.ObjectId(purchaseId.toString());
      const items = await this.purchaseItemModel.find({ 
        purchase_id: objectId 
      })
        .populate('product_id')
        .populate('warehouse_id')
        .populate('purchase_id')
        .exec();
      console.log(`Found ${items.length} purchase items for purchase ID: ${purchaseId}`);
      console.log('Purchase items:', JSON.stringify(items, null, 2));
      return items;
    } catch (error) {
      console.error(`Error fetching purchase items for purchase ID: ${purchaseId}`, error);
      throw error;
    }
  }
}

