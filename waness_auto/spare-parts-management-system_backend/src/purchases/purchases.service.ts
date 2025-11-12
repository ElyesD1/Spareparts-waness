import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { CreatePurchaseDto } from './dto/create-purchase.dto';
import { Purchase, PurchaseDocument } from './purchase.entity';
import { PurchaseItemService } from '../purchase-item/purchase-item.service';
import { ProductStocksService } from '../product-stocks/product-stocks.service';
import { StockMovementService } from '../stock-movement/stock-movement.service';
import { MovementType } from '../stock-movement/dto/create-stock-movement.dto';
import { SupplierCreditsService } from '../supplier-credits/supplier-credits.service';

@Injectable()
export class PurchasesService {
  constructor(
    @InjectModel(Purchase.name)
    private readonly purchaseModel: Model<PurchaseDocument>,
    private readonly purchaseItemService: PurchaseItemService,
    private readonly productStocksService: ProductStocksService,
    private readonly stockMovementService: StockMovementService,
    private readonly supplierCreditsService: SupplierCreditsService,
  ) {}

  async create(createPurchaseDto: CreatePurchaseDto): Promise<Purchase> {
    // Create the purchase first with original amount
    const purchase = new this.purchaseModel({
      ...createPurchaseDto,
      status: createPurchaseDto.status || 'pending',
      created_by: new Types.ObjectId(createPurchaseDto.created_by as any),
      supplier_id: new Types.ObjectId(createPurchaseDto.supplier_id as any),
    });
    
    const savedPurchase = await purchase.save();
    const purchaseId = (savedPurchase as any)._id.toString();
    
    // Auto-apply available supplier credits
    try {
      const creditResult = await this.supplierCreditsService.autoApplyCreditsToPurchase(purchaseId);
      console.log(`Auto-applied ${creditResult.appliedAmount} credits to purchase ${purchaseId}`);
      
      // Return the updated purchase with credit information
      const updatedPurchase = await this.findOne(purchaseId);
      if (!updatedPurchase) {
        throw new Error(`Purchase with ID ${purchaseId} not found after credit application`);
      }
      return updatedPurchase;
    } catch (error) {
      console.error('Error applying supplier credits:', error);
      // Return the purchase even if credit application fails
      return savedPurchase.toObject();
    }
  }

  async findAll(): Promise<Purchase[]> {
    const purchases = await this.purchaseModel.find()
      .populate('created_by')
      .populate('delivered_by')
      .populate('supplier_id')
      .exec();

    // Fetch items for each purchase and calculate totals
    const purchasesWithCalculatedTotals = await Promise.all(
      purchases.map(async (purchase) => {
        const purchaseObj: any = purchase.toObject();
        
        // Fetch items using purchase item service
        const items = await this.purchaseItemService.findByPurchaseId(purchaseObj._id.toString());
        
        // Calculate total from items
        const calculatedTotal = items.reduce((sum: number, item: any) => {
          return sum + (item.quantity * item.unit_price);
        }, 0);
        
        return {
          ...purchaseObj,
          total_amount: calculatedTotal || purchaseObj.total_amount,
          final_amount: purchaseObj.final_amount || (calculatedTotal - (purchaseObj.credit_applied || 0)),
        };
      })
    );

    return purchasesWithCalculatedTotals;
  }

  async findOne(id: string): Promise<Purchase | null> {
    const purchase = await this.purchaseModel.findById(id)
      .populate('created_by')
      .populate('delivered_by')
      .populate('supplier_id')
      .exec();
    
    if (!purchase) return null;

    // Fetch items and calculate total
    const items = await this.purchaseItemService.findByPurchaseId(id);
    const calculatedTotal = items.reduce((sum: number, item: any) => {
      return sum + (item.quantity * item.unit_price);
    }, 0);

    const purchaseObj: any = purchase.toObject();
    return {
      ...purchaseObj,
      total_amount: calculatedTotal || purchaseObj.total_amount,
      final_amount: purchaseObj.final_amount || (calculatedTotal - (purchaseObj.credit_applied || 0)),
    } as Purchase;
  }

  async update(id: string, updatePurchaseDto: Partial<Purchase>): Promise<Purchase | null> {
    await this.purchaseModel.findByIdAndUpdate(id, updatePurchaseDto, { new: true }).exec();
    return this.findOne(id);
  }

  async remove(id: string): Promise<{ deleted: boolean }> {
    const result = await this.purchaseModel.findByIdAndDelete(id).exec();
    return { deleted: !!result };
  }

  async deliver(id: string, deliveredBy: string): Promise<Purchase | null> {
    const deliveredAt = new Date();
    await this.purchaseModel.findByIdAndUpdate(id, {
      status: 'delivered',
      delivered_by: new Types.ObjectId(deliveredBy),
      deliveredAt,
    }, { new: true }).exec();

    // Add stock and create stock movements for all purchase items
    const purchaseItems = await this.purchaseItemService.findByPurchaseId(id);
    
    for (const item of purchaseItems) {
      try {
        const itemObj: any = item;
        // Handle populated or non-populated product_id/warehouse_id
        const productId = (itemObj.product_id?._id || itemObj.product_id).toString();
        const warehouseId = (itemObj.warehouse_id?._id || itemObj.warehouse_id).toString();
        
        // Add stock to the product
        await this.productStocksService.incrementStock(
          productId, 
          warehouseId, 
          itemObj.quantity
        );
        
        // Get product name for the note
        const productName = itemObj.product?.name || 'N/A';
        
        // Create stock movement record with all details
        await this.stockMovementService.create({
          product_id: productId as any,
          quantity: itemObj.quantity,
          movement_type: MovementType.PURCHASE,
          from_warehouse_id: undefined,
          to_warehouse_id: warehouseId as any,
          user_id: deliveredBy as any,
          note: `Achat livré: Produit: ${productName} - Quantité: ${itemObj.quantity} - Prix: ${itemObj.unit_price}`,
        });
        
        console.log(`Added ${itemObj.quantity} units of product ${productId} to warehouse ${warehouseId}`);
      } catch (e) {
        console.error(`Error processing item ${item.product_id}:`, e);
        // Continue with other items even if one fails
      }
    }
    
    console.log('All purchase items processed successfully');
    return this.findOne(id);
  }
}

