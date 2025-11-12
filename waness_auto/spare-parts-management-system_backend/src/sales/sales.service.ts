import { Injectable } from '@nestjs/common';
import { InjectModel, InjectConnection } from '@nestjs/mongoose';
import { Model, Types, Connection } from 'mongoose';
import { CreateSaleDto } from './dto/create-sale.dto';
import { Sale, SaleDocument } from './sale.entity';
import { SaleItemService } from '../sale-item/sale-item.service';
import { Warehouse } from '../warehouses/entities/warehouse.entity';

@Injectable()
export class SalesService {
  constructor(
    @InjectModel(Sale.name)
    private readonly saleModel: Model<SaleDocument>,
    private readonly saleItemService: SaleItemService,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  async create(createSaleDto: CreateSaleDto, userId: string): Promise<Sale> {
    const { items, ...saleData } = createSaleDto;

    // Debug: Log the incoming data
    console.log('[SalesService] Create sale request:', createSaleDto);
    console.log('[SalesService] Warehouse ID being sent:', saleData.warehouse_id);
    console.log('[SalesService] Type of warehouse_id:', typeof saleData.warehouse_id);

    // Validate warehouse_id exists and is not null
    if (!saleData.warehouse_id || saleData.warehouse_id === null || saleData.warehouse_id === undefined) {
      throw new Error('warehouse_id is required and cannot be null');
    }

    // Check if warehouse exists
    const warehouseModel = this.connection.model(Warehouse.name);
    const warehouse = await warehouseModel.findById(saleData.warehouse_id).exec();

    console.log('[SalesService] Warehouse check result:', warehouse);

    if (!warehouse) {
      throw new Error(`Warehouse with ID ${saleData.warehouse_id} does not exist`);
    }

    console.log('[SalesService] Warehouse validation passed:', warehouse);

    // Validate that all products are from the selected warehouse
    if (items && items.length > 0) {
      await this.validateProductsFromWarehouse(items, saleData.warehouse_id.toString());
    }

    console.log('[SalesService] Creating MongoDB sale document...');
    
    // Create the sale
    const sale = new this.saleModel({
      ...saleData,
      warehouse_id: new Types.ObjectId(saleData.warehouse_id as any),
      created_by: new Types.ObjectId(userId),
      source_credit_sale_id: null
    });

    const savedSale = await sale.save();
    const saleId = (savedSale as any)._id.toString();
    
    console.log('[SalesService] Sale saved with ID:', saleId);

    // Create sale items if provided
    if (items && items.length > 0) {
      console.log('[SalesService] Creating sale items...');
      
      for (const item of items) {
        console.log('[SalesService] Processing item:', item);
        
        // Validate that the product exists
        const productModel = this.connection.model('Product');
        const product = await productModel.findById(item.product_id).exec();
        
        if (!product) {
          throw new Error(`Product with ID ${item.product_id} does not exist`);
        }
        
        console.log('[SalesService] Product validated:', product);
        
        // Create the sale item
        await this.saleItemService.create({
          ...item,
          sale_id: saleId as any,
        }, userId);
        
        console.log('[SalesService] Sale item created successfully');
      }
    }

    // Fetch and return the created sale
    const createdSale = await this.findOne(saleId);
    console.log('[SalesService] Created sale:', createdSale);
    
    if (!createdSale) {
      throw new Error('Failed to create sale - could not retrieve created sale');
    }
    
    return createdSale;
  }

  async findAll(): Promise<any[]> {
    console.log('[SalesService] Finding all sales');
    
    const sales = await this.saleModel.find()
      .populate('warehouse_id')
      .populate('created_by')
      .exec();
    console.log('[SalesService] Found', sales.length, 'sales in database');
    console.log('[SalesService] Raw sales data:', sales);
    
    const salesWithItems = await Promise.all(sales.map(async sale => {
      const saleObj: any = sale.toObject();
      const saleId = saleObj._id.toString();
      console.log('[SalesService] Processing sale ID:', saleId);
      try {
        const items = await this.saleItemService.findBySaleId(saleId);
        console.log('[SalesService] Found', items.length, 'items for sale', saleId);
        
        const saleWithItems = {
          ...saleObj,
          id: saleId,
          warehouse: saleObj.warehouse_id ? {
            id: saleObj.warehouse_id._id?.toString() || saleObj.warehouse_id.toString(),
            name: saleObj.warehouse_id.name || 'Unknown'
          } : null,
          items: items.map((item: any) => ({
            unit_price: item.unit_price,
            supplier_price: item.product_id?.supplier_price ?? null,
            quantity: item.quantity,
          })),
        };
        console.log('[SalesService] Sale with items:', saleWithItems);
        return saleWithItems;
      } catch (error) {
        console.error('[SalesService] Error fetching items for sale', saleId, ':', error);
        return {
          ...saleObj,
          id: saleId,
          items: [],
        };
      }
    }));
    
    console.log('[SalesService] Returning', salesWithItems.length, 'sales with items');
    return salesWithItems;
  }

  async findOne(id: string): Promise<Sale | null> {
    console.log('[SalesService] Finding sale with ID:', id);
    
    const sale = await this.saleModel.findById(id).exec();
    console.log('[SalesService] Found sale:', sale);
    
    return sale;
  }

  async update(id: string, updateSaleDto: Partial<Sale>): Promise<Sale | null> {
    console.log('[SalesService] Updating sale with ID:', id);
    console.log('[SalesService] Update data:', updateSaleDto);
  
    const updateData: any = { ...updateSaleDto };
  
    // Handle warehouse_id conversion
    if (updateSaleDto.warehouse_id) {
      updateData.warehouse_id = new Types.ObjectId(updateSaleDto.warehouse_id as any);
    }
  
    // Handle created_by conversion
    if ((updateSaleDto as any).created_by) {
      updateData.created_by = new Types.ObjectId((updateSaleDto as any).created_by);
    }
  
    await this.saleModel.findByIdAndUpdate(id, updateData, { new: true }).exec();
  
    console.log('[SalesService] Sale updated in database');
  
    const updatedSale = await this.findOne(id);
    console.log('[SalesService] Updated sale:', updatedSale);
  
    return updatedSale;
  }

  async remove(id: string): Promise<{ deleted: boolean }> {
    console.log('[SalesService] Removing sale with ID:', id);
    
    // First, get the sale to get the user ID
    const sale: any = await this.findOne(id);
    console.log('[SalesService] Found sale:', sale);
    
    if (!sale) {
      console.log('[SalesService] Sale not found, returning false');
      return { deleted: false };
    }
    
    const userId = sale.created_by?._id?.toString() || sale.created_by?.toString();
    console.log('[SalesService] Sale created_by:', userId);
    
    // Get all sale items for this sale
    const saleItems = await this.saleItemService.findBySaleId(id);
    console.log('[SalesService] Found', saleItems.length, 'sale items to delete');
    
    // Delete all sale items first
    for (const item of saleItems) {
      const itemObj: any = item;
      const itemId = itemObj._id?.toString() || itemObj.id;
      console.log('[SalesService] Deleting sale item:', itemId);
      await this.saleItemService.remove(itemId, userId);
      console.log('[SalesService] Sale item deleted successfully');
    }
    
    // Then delete the sale
    console.log('[SalesService] Deleting the sale itself');
    const result = await this.saleModel.findByIdAndDelete(id).exec();
    console.log('[SalesService] Sale deletion result:', result);
    
    const deleted = !!result;
    console.log('[SalesService] Final deletion result:', { deleted });
    return { deleted };
  }

  private async validateProductsFromWarehouse(items: any[], warehouseId: string): Promise<void> {
    console.log('[SalesService] Validating products from warehouse:', warehouseId);
    
    const productStocksModel = this.connection.model('ProductStock');
    
    for (const item of items) {
      const stock = await productStocksModel.findOne({
        product_id: new Types.ObjectId(item.product_id),
        warehouse_id: new Types.ObjectId(warehouseId)
      }).exec();
      
      if (!stock) {
        throw new Error(`Product with ID ${item.product_id} is not available in warehouse ${warehouseId}`);
      }
      
      const availableStock = stock.quantity || 0;
      if (availableStock < item.quantity) {
        throw new Error(`Insufficient stock for product ID ${item.product_id}. Available: ${availableStock}, Requested: ${item.quantity}`);
      }
      
      console.log(`[SalesService] Product ${item.product_id} validated - Available: ${availableStock}, Requested: ${item.quantity}`);
    }
    
    console.log('[SalesService] All products validated successfully');
  }

  async getProductsByWarehouse(warehouseId: string): Promise<any[]> {
    console.log('[SalesService] Getting products for warehouse:', warehouseId);
    
    const productStocksModel = this.connection.model('ProductStock');
    const productModel = this.connection.model('Product');
    
    // Get all product stocks for this warehouse
    const stocks = await productStocksModel.find({
      warehouse_id: new Types.ObjectId(warehouseId)
    }).exec();
    
    const productIds = stocks.map((s: any) => s.product_id);
    
    // Get product details
    const products = await productModel.find({
      _id: { $in: productIds }
    }).exec();
    
    // Merge stock data with product data
    const productsWithStock = products.map((product: any) => {
      const productObj = product.toObject();
      const stock = stocks.find((s: any) => s.product_id.toString() === productObj._id.toString());
      
      return {
        id: productObj._id.toString(),
        name: productObj.name,
        description: productObj.description,
        supplier_price: productObj.supplier_price,
        sale_price: productObj.unit_price,
        image_url: productObj.image,
        category: productObj.category,
        supplier_id: productObj.supplier_id?.toString(),
        stock_quantity: stock ? stock.quantity : 0,
        warehouse_id: warehouseId,
      };
    });
    
    console.log('[SalesService] Found', productsWithStock.length, 'products for warehouse', warehouseId);
    
    return productsWithStock;
  }
}

