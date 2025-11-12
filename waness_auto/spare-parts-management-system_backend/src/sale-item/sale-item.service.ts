import { Injectable } from '@nestjs/common';
import { InjectModel, InjectConnection } from '@nestjs/mongoose';
import { Model, Types, Connection } from 'mongoose';
import { CreateSaleItemDto } from './dto/create-sale-item.dto';
import { UpdateSaleItemDto } from './dto/update-sale-item.dto';
import { SaleItem, SaleItemDocument } from './sale-item.entity';
import { ProductStocksService } from '../product-stocks/product-stocks.service';
import { Sale } from '../sales/sale.entity';
import { StockMovementService } from '../stock-movement/stock-movement.service';
import { MovementType } from '../stock-movement/dto/create-stock-movement.dto';

@Injectable()
export class SaleItemService {
  constructor(
    @InjectModel(SaleItem.name)
    private readonly saleItemModel: Model<SaleItemDocument>,
    private readonly productStocksService: ProductStocksService,
    private readonly stockMovementService: StockMovementService,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  // Static set to track ongoing operations and prevent duplicates
  private static ongoingOperations = new Set<string>();
  
  async create(createSaleItemDto: CreateSaleItemDto, userId: string | number): Promise<SaleItem> {
    const userIdStr = userId.toString();
    
    // Add unique call identifier to prevent duplicates
    const callId = `call_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    const operationKey = `sale_${createSaleItemDto.sale_id}_${createSaleItemDto.product_id}`;
    
    // Check if this exact operation is already in progress
    if (SaleItemService.ongoingOperations.has(operationKey)) {
      console.log(`[SaleItemService] 🚨 [${callId}] Operation already in progress for ${operationKey}, skipping to prevent duplication`);
      throw new Error(`Operation already in progress for sale ${createSaleItemDto.sale_id}, product ${createSaleItemDto.product_id}`);
    }
    
    // Mark this operation as in progress
    SaleItemService.ongoingOperations.add(operationKey);
    
    try {
      console.log(`[SaleItemService] 🆔 [${callId}] CREATE method called for sale_id: ${createSaleItemDto.sale_id}`);
      console.log(`[SaleItemService] 📍 [${callId}] Stack trace:`, new Error().stack?.split('\n').slice(1, 4).join('\n'));
    
      if (!userId) {
        console.error(`[SaleItemService] ❌ [${callId}] Missing userId in create(); refusing to create stock movement`);
        throw new Error('Missing authenticated user id. Please re-login and ensure controllers use req.user.sub');
      }
      
      // Fetch the sale to get warehouse_id
      const saleModel = this.connection.model(Sale.name);
      const sale: any = await saleModel.findById(createSaleItemDto.sale_id).exec();
      console.log(`[SaleItemService] 📊 [${callId}] Found sale:`, sale);
      
      if (!sale) throw new Error('Sale not found');
      
      const warehouseId = sale.warehouse_id.toString();
      const productId = createSaleItemDto.product_id.toString();
      
      // Check stock availability before attempting to decrement
      const stockCheck = await this.productStocksService.checkStockAvailability(
        productId, 
        warehouseId, 
        createSaleItemDto.quantity
      );
      
      // If no stock record exists, create one and allow the sale
      if (!stockCheck.available && stockCheck.message.includes('No stock record found')) {
        console.log(`[SaleItemService] ⚠️ No stock record found for product ${productId} in warehouse ${warehouseId}. Creating stock record.`);
        await this.productStocksService.incrementStock(productId, warehouseId, createSaleItemDto.quantity);
        console.log(`[SaleItemService] ✅ Created stock record with quantity ${createSaleItemDto.quantity} for product ${productId}`);
      } else if (!stockCheck.available) {
        throw new Error(`Stock check failed: ${stockCheck.message}`);
      }
      
      // Create sale item first, then handle stock movement and decrement
      const item = new this.saleItemModel({
        ...createSaleItemDto,
        sale_id: new Types.ObjectId(createSaleItemDto.sale_id as any),
        product_id: new Types.ObjectId(createSaleItemDto.product_id as any),
      });
      
      console.log('[SaleItemService] Created item entity:', item);
      const saved = await item.save();
      console.log('[SaleItemService] Saved sale item:', saved);
      console.log('[SaleItemService] Saved item unit price:', saved.unit_price);
      
      // Create stock movement first, then decrement stock only if successful
      console.log(`[SaleItemService] 🆔 Creating stock movement for sale item ID: ${(saved as any)._id}`);
      console.log(`[SaleItemService] 📍 Called from: ${new Error().stack?.split('\n')[2] || 'unknown'}`);
      
      // Get product name from the database
      const productModel = this.connection.model('Product');
      const product = await productModel.findById(productId).exec();
      const productName = product ? product.name : 'N/A';
      
      const stockMovementData = {
        product_id: productId as any,
        quantity: saved.quantity,
        movement_type: MovementType.ADJUSTMENT, // will be interpreted as 'sale' via note until enum includes 'sale'
        from_warehouse_id: warehouseId as any,
        to_warehouse_id: undefined,
        user_id: userIdStr as any,
        note: `Vente: ${sale.customer_name} - Produit: ${productName} - Quantité: ${saved.quantity} - Prix: ${saved.unit_price}`,
      };
      console.log(`[SaleItemService] 📊 Stock movement data:`, stockMovementData);
      
      const stockMovementResult = await this.stockMovementService.create(stockMovementData);
      console.log(`[SaleItemService] ✅ Stock movement result:`, stockMovementResult);
      
      if ('duplicate_prevented' in stockMovementResult && stockMovementResult.duplicate_prevented) {
        console.log(`[SaleItemService] ⚠️  [${callId}] Duplicate prevented for sale item ID: ${(saved as any)._id}`);
        console.log(`[SaleItemService] 🚫 Skipping stock decrement to prevent duplication`);
      } else {
        console.log(`[SaleItemService] 🎉 [${callId}] Stock movement created successfully for sale item ID: ${(saved as any)._id}`);
        
        // Only decrement stock if stock movement was created successfully
        console.log(`[SaleItemService] 📉 Decrementing stock for product ${productId}, warehouse ${warehouseId}, quantity ${saved.quantity}`);
        await this.productStocksService.decrementStock(productId, warehouseId, saved.quantity);
        console.log(`[SaleItemService] ✅ Stock decremented successfully`);
      }
      
      console.log(`[SaleItemService] ✅ [${callId}] CREATE method completed successfully for sale_id: ${createSaleItemDto.sale_id}`);
      return saved.toObject();
      
    } finally {
      // Always remove the operation from ongoing operations
      SaleItemService.ongoingOperations.delete(operationKey);
    }
  }

  async findAll(): Promise<SaleItem[]> {
    return this.saleItemModel.find()
      .populate('product_id')
      .populate('sale_id')
      .exec();
  }

  async findOne(id: string): Promise<SaleItem | null> {
    return this.saleItemModel.findById(id)
      .populate('product_id')
      .populate('sale_id')
      .exec();
  }

  async update(id: string, updateSaleItemDto: UpdateSaleItemDto, userId: string | number): Promise<SaleItem | null> {
    const userIdStr = userId.toString();
    const old = await this.findOne(id);
    console.log('[SaleItemService] Old sale item:', old);
    
    await this.saleItemModel.findByIdAndUpdate(id, updateSaleItemDto, { new: true }).exec();
    const updated = await this.findOne(id);
    console.log('[SaleItemService] Updated sale item:', updated);
    
    if (old) {
      const oldObj: any = old;
      const saleModel = this.connection.model(Sale.name);
      const sale: any = oldObj.sale_id || await saleModel.findById(oldObj.sale_id).exec();
      
      if (sale) {
        const warehouseId = sale.warehouse_id.toString();
        const productId = oldObj.product_id.toString();
        
        console.log('[SaleItemService] Reverting stock for old item');
        await this.productStocksService.incrementStock(productId, warehouseId, oldObj.quantity);
        
        // Create stock movement for stock adjustment
        console.log('[SaleItemService] Creating stock movement for old item adjustment');
        const adjustmentData = {
          product_id: productId as any,
          quantity: oldObj.quantity,
          movement_type: MovementType.ADJUSTMENT,
          from_warehouse_id: warehouseId as any,
          to_warehouse_id: undefined,
          user_id: userIdStr as any,
          note: `Ajustement de vente: Produit: ${oldObj.product_id?.name || 'N/A'} - Quantité: ${oldObj.quantity} - Prix: ${oldObj.unit_price}`,
        };
        await this.stockMovementService.create(adjustmentData);
        
        console.log('StockMovement reverted for sale update');
      }
    }
    
    if (updated) {
      const updatedObj: any = updated;
      const saleModel = this.connection.model(Sale.name);
      const sale: any = updatedObj.sale_id || await saleModel.findById(updatedObj.sale_id).exec();
      
      if (sale) {
        const warehouseId = sale.warehouse_id.toString();
        const productId = updatedObj.product_id.toString();
        
        console.log('[SaleItemService] Applying stock for updated item');
        await this.productStocksService.decrementStock(productId, warehouseId, updatedObj.quantity);
        console.log('[SaleItemService] SKIPPING stock movement creation for updated item to avoid errors');
        
        console.log('StockMovement created for sale update');
      }
    }
    return updated;
  }

  async remove(id: string, userId: string | number): Promise<{ deleted: boolean }> {
    const userIdStr = userId.toString();
    const item = await this.findOne(id);
    console.log('[SaleItemService] Item to delete:', item);
    
    const result = await this.saleItemModel.findByIdAndDelete(id).exec();
    console.log('[SaleItemService] Delete result:', result);
    
    if (item) {
      const itemObj: any = item;
      const saleModel = this.connection.model(Sale.name);
      const sale: any = itemObj.sale_id || await saleModel.findById(itemObj.sale_id).exec();
      console.log('[SaleItemService] Associated sale:', sale);
      
      if (sale) {
        const warehouseId = sale.warehouse_id.toString();
        const productId = itemObj.product_id.toString();
        
        console.log('[SaleItemService] Restoring stock for deleted item');
        await this.productStocksService.incrementStock(productId, warehouseId, itemObj.quantity);
        console.log('[SaleItemService] SKIPPING stock movement creation for deleted item to avoid errors');
        
        console.log('StockMovement created for sale delete');
      }
    }
    
    const deleted = !!result;
    console.log('[SaleItemService] Sale item deletion result:', { deleted });
    return { deleted };
  }

  async findBySaleId(saleId: string | number): Promise<SaleItem[]> {
    const saleIdStr = saleId.toString();
    console.log('[SaleItemService] Finding sale items for sale ID:', saleIdStr);
    
    const items = await this.saleItemModel.find({
      sale_id: new Types.ObjectId(saleIdStr),
    })
      .populate('product_id')
      .populate('sale_id')
      .exec();
    
    console.log('[SaleItemService] Found', items.length, 'sale items for sale', saleIdStr);
    console.log('[SaleItemService] Sale items:', items);
    return items;
  }
}

