import { Injectable, NotFoundException, BadRequestException, Optional, Inject } from '@nestjs/common';
import { InjectModel, InjectConnection } from '@nestjs/mongoose';
import { Model, Types, Connection, ClientSession } from 'mongoose';
import { CreditSale, CreditSaleDocument } from './credit-sale.entity';
import { CreateCreditSaleDto } from './dto/create-credit-sale.dto';
import { CustomersService } from '../customers/customers.service';
import { ProductStocksService } from '../product-stocks/product-stocks.service';
import { CreditSaleItem, CreditSaleItemDocument } from '../credit-sale-items/credit-sale-item.entity';
import { SalesService } from '../sales/sales.service';
import { CreditPayment, CreditPaymentDocument } from '../credit-payments/credit-payment.entity';

@Injectable()
export class CreditSalesService {
  constructor(
    @InjectModel(CreditSale.name)
    private creditSaleModel: Model<CreditSaleDocument>,
    @InjectModel(CreditSaleItem.name)
    private creditSaleItemModel: Model<CreditSaleItemDocument>,
    @InjectModel(CreditPayment.name)
    private creditPaymentModel: Model<CreditPaymentDocument>,
    private customersService: CustomersService,
    private productStocksService: ProductStocksService,
    @InjectConnection() private readonly connection: Connection,
    @Optional() private readonly salesService?: SalesService,
  ) {}

  async create(createCreditSaleDto: CreateCreditSaleDto, userId: string): Promise<CreditSale> {
    console.log('=== BACKEND: CREDIT SALE CREATION START ===');
    console.log('Input DTO:', createCreditSaleDto);
    console.log('User ID from JWT:', userId);

    // Idempotency guard: return an existing identical credit sale created very recently
    try {
      const twoMinutesAgo = new Date(Date.now() - 2 * 60 * 1000);
      const existingRecent = await this.creditSaleModel.findOne({
        customer_id: new Types.ObjectId(createCreditSaleDto.customer_id as any),
        warehouse_id: new Types.ObjectId(createCreditSaleDto.warehouse_id as any),
        total_amount: createCreditSaleDto.total_amount,
        down_payment: createCreditSaleDto.down_payment,
        installment_count: createCreditSaleDto.installment_count,
        first_payment_date: createCreditSaleDto.first_payment_date,
        createdAt: { $gte: twoMinutesAgo }
      })
        .sort({ createdAt: -1 })
        .exec();
        
      if (existingRecent) {
        console.log('[Idempotency] Returning recently created identical credit sale:', (existingRecent as any)._id);
        return this.findOne((existingRecent as any)._id.toString());
      }
    } catch (e) {
      console.warn('[Idempotency] Recent duplicate check failed (non-fatal):', e?.message || e);
    }

    // Additional validation for items
    if (!createCreditSaleDto.items || !Array.isArray(createCreditSaleDto.items)) {
      throw new BadRequestException('Items must be a valid array');
    }
    
    if (createCreditSaleDto.items.length === 0) {
      throw new BadRequestException('At least one item is required');
    }

    // Validate each item has required fields
    for (const item of createCreditSaleDto.items) {
      if (!item.product_id || !item.quantity || !item.unit_price) {
        throw new BadRequestException(`Item missing required fields: product_id=${item.product_id}, quantity=${item.quantity}, unit_price=${item.unit_price}`);
      }
      
      // Ensure numeric values
      if (isNaN(Number(item.quantity)) || isNaN(Number(item.unit_price))) {
        throw new BadRequestException(`Invalid numeric values: quantity=${item.quantity}, unit_price=${item.unit_price}`);
      }
      
      // Ensure positive values
      if (Number(item.quantity) <= 0 || Number(item.unit_price) < 0) {
        throw new BadRequestException(`Invalid values: quantity must be > 0, unit_price must be >= 0`);
      }
    }

    // Validate that all products are from the selected warehouse
    if (createCreditSaleDto.items && createCreditSaleDto.items.length > 0) {
      await this.validateProductsFromWarehouse(createCreditSaleDto.items, createCreditSaleDto.warehouse_id.toString());
    }

    // Calculate credit amount
    const creditAmount = createCreditSaleDto.total_amount - createCreditSaleDto.down_payment;
    
    // Validate credit amount
    if (creditAmount <= 0) {
      throw new BadRequestException('Credit amount must be greater than 0');
    }
    
    if (createCreditSaleDto.installment_count <= 0) {
      throw new BadRequestException('Installment count must be greater than 0');
    }

    const monthlyPayment = createCreditSaleDto.monthly_payment || (creditAmount / createCreditSaleDto.installment_count);

    // Validate stock availability before creating the credit sale
    for (const item of createCreditSaleDto.items) {
      const stockCheck = await this.productStocksService.checkStockAvailability(
        item.product_id.toString(),
        createCreditSaleDto.warehouse_id.toString(),
        item.quantity
      );
      
      if (!stockCheck.available) {
        throw new BadRequestException(stockCheck.message);
      }
    }

    // Remove transaction for standalone MongoDB
    // const session: ClientSession = await this.connection.startSession();
    // session.startTransaction();

    try {
      // Create credit sale
      const creditSale = new this.creditSaleModel({
        customer_id: new Types.ObjectId(createCreditSaleDto.customer_id as any),
        warehouse_id: new Types.ObjectId(createCreditSaleDto.warehouse_id as any),
        created_by: new Types.ObjectId(userId),
        sale_date: createCreditSaleDto.sale_date,
        total_amount: createCreditSaleDto.total_amount,
        down_payment: createCreditSaleDto.down_payment,
        credit_amount: creditAmount,
        installment_count: createCreditSaleDto.installment_count,
        monthly_payment: monthlyPayment,
        first_payment_date: createCreditSaleDto.first_payment_date,
        notes: createCreditSaleDto.notes || '',
        status: 'active',
      });

      const savedCreditSale = await creditSale.save();
      const creditSaleId = (savedCreditSale as any)._id.toString();
      console.log('Credit sale saved with ID:', creditSaleId);

      // Create credit sale items
      for (const item of createCreditSaleDto.items) {
        console.log('Processing item:', item);
        
        // Validate item data before creating
        if (!item.quantity || !item.unit_price || isNaN(item.quantity) || isNaN(item.unit_price)) {
          throw new BadRequestException(`Invalid item data: quantity=${item.quantity}, unit_price=${item.unit_price}`);
        }

        // Safely calculate total price with proper number conversion
        const quantity = Number(item.quantity);
        const unitPrice = Number(item.unit_price);
        const totalPrice = quantity * unitPrice;
        
        console.log(`Calculating total price: ${quantity} * ${unitPrice} = ${totalPrice}`);
        
        // Validate calculated total price
        if (isNaN(totalPrice) || totalPrice <= 0) {
          throw new BadRequestException(`Invalid total price calculation: ${quantity} * ${unitPrice} = ${totalPrice}`);
        }
        
        // Additional safety check for extremely large numbers
        if (!isFinite(totalPrice)) {
          throw new BadRequestException(`Total price calculation resulted in invalid number: ${totalPrice}`);
        }

        // Create credit sale item
        const creditSaleItem = new this.creditSaleItemModel({
          credit_sale_id: new Types.ObjectId(creditSaleId),
          product_id: new Types.ObjectId(item.product_id as any),
          quantity,
          unit_price: unitPrice,
          total_price: totalPrice,
        });

        await creditSaleItem.save();
        console.log('Credit sale item saved successfully');
      }

      // await session.commitTransaction();
      console.log('=== BACKEND: CREDIT SALE CREATION SUCCESS ===');
      console.log('All items saved successfully');
      
      // Update customer balance and product stocks
      try {
        await this.customersService.updateBalance(createCreditSaleDto.customer_id.toString(), creditAmount);
        console.log('Customer balance updated successfully');
        
        for (const item of createCreditSaleDto.items) {
          await this.productStocksService.decrementStock(
            item.product_id.toString(),
            createCreditSaleDto.warehouse_id.toString(),
            item.quantity
          );
          console.log(`Stock decremented for product ${item.product_id}`);
        }
      } catch (error) {
        console.error('Error updating customer balance or product stocks:', error);
        // Don't throw here as the credit sale was already created successfully
      }
      
      // Return the saved credit sale with relations
      const result = await this.findOne(creditSaleId);
      console.log('Final credit sale result:', result);
      return result;
    } catch (error) {
      console.log('=== BACKEND: CREDIT SALE CREATION ERROR ===');
      console.log('Error:', error);
      // No transaction to rollback in standalone MongoDB
      throw error;
    }
  }

  async findAll(): Promise<CreditSale[]> {
    const creditSales = await this.creditSaleModel.find()
      .populate('customer_id')
      .populate('warehouse_id')
      .populate('created_by')
      .sort({ createdAt: -1 })
      .exec();

    // Populate payments for each credit sale using direct model query
    const creditSalesWithPayments = await Promise.all(
      creditSales.map(async (sale) => {
        const saleObj = sale.toObject();
        // Query payments directly from the model
        const payments = await this.creditPaymentModel
          .find({ credit_sale_id: (sale as any)._id })
          .populate('received_by')
          .exec();
        return {
          ...saleObj,
          payments: payments.map(p => p.toObject()),
        };
      })
    );

    return creditSalesWithPayments as any;
  }

  async findOne(id: string): Promise<CreditSale> {
    const creditSale = await this.creditSaleModel.findById(id)
      .populate('customer_id')
      .populate('warehouse_id')
      .populate('created_by')
      .exec();
      
    if (!creditSale) {
      throw new NotFoundException(`Credit sale with ID ${id} not found`);
    }
    return creditSale;
  }

  async findByCustomer(customerId: string): Promise<any[]> {
    const creditSales = await this.creditSaleModel.find({ 
      customer_id: new Types.ObjectId(customerId) 
    })
      .sort({ createdAt: -1 })
      .exec();
    
    // Calculate paid and remaining amounts for each credit sale
    const creditSalesWithCalculations = await Promise.all(
      creditSales.map(async (creditSale: any) => {
        const creditSaleObj = creditSale.toObject();
        const totalPaid = await this.calculateTotalPaid(creditSaleObj._id.toString());
        const remaining = Number(creditSaleObj.credit_amount) - totalPaid;
        
        return {
          ...creditSaleObj,
          id: creditSaleObj._id.toString(),
          total_paid: totalPaid,
          remaining_amount: remaining,
          is_completed: remaining <= 0
        };
      })
    );
    
    return creditSalesWithCalculations;
  }

  async remove(id: string): Promise<{ deleted: boolean }> {
    await this.findOne(id); // Validate exists
    // Delete child items first
    await this.creditSaleItemModel.deleteMany({ 
      credit_sale_id: new Types.ObjectId(id) 
    }).exec();
    
    const result = await this.creditSaleModel.findByIdAndDelete(id).exec();
    return { deleted: !!result };
  }

  async updateStatus(id: string, status: string): Promise<CreditSale> {
    console.log(`[CreditSalesService] updateStatus called - ID: ${id}, New Status: ${status}`);
    
    const validStatuses = ['pending', 'active', 'completed', 'overdue'];
    if (!validStatuses.includes(status)) {
      throw new BadRequestException(`Invalid status. Must be one of: ${validStatuses.join(', ')}`);
    }

    await this.creditSaleModel.findByIdAndUpdate(id, { status }, { new: true }).exec();
    console.log(`[CreditSalesService] Status updated in database to: ${status}`);
    
    const saved = await this.findOne(id);
    console.log(`[CreditSalesService] Credit sale retrieved after update`);

    // If a credit sale becomes completed (paid), mirror it as a normal Sale
    try {
      if (status === 'completed' && this.salesService) {
        console.log('[CreditSalesService] Status is "completed", checking for existing mirror...');
        
        const saleModel = this.connection.model('Sale');
        const existingMirror = await saleModel.findOne({ 
          source_credit_sale_id: id  // Query by string, not ObjectId
        }).exec();
        
        if (existingMirror) {
          console.log('[CreditSalesService] ✅ Mirror sale already exists:', existingMirror._id);
        } else {
          console.log('[CreditSalesService] No existing mirror found, creating new one...');
          
          const items = await this.creditSaleItemModel.find({ 
            credit_sale_id: new Types.ObjectId(id) 
          }).exec();
          
          console.log(`[CreditSalesService] Found ${items.length} items for credit sale`);
          
          if (items.length > 0) {
            const creditSale: any = saved;
            
            // Extract IDs from populated fields
            const customerId = creditSale.customer_id?._id?.toString() || creditSale.customer_id?.toString();
            const warehouseId = creditSale.warehouse_id?._id?.toString() || creditSale.warehouse_id?.toString();
            const createdById = creditSale.created_by?._id?.toString() || creditSale.created_by?.toString();
            
            console.log('[CreditSalesService] Extracted IDs:', { customerId, warehouseId, createdById });
            
            const customerModel = this.connection.model('Customer');
            const customer = await customerModel.findById(customerId).exec();
            const customerName = customer?.name || `Customer#${customerId}`;
            
            console.log('[CreditSalesService] Customer name:', customerName);
            
            // Create mirror sale directly without triggering stock decrement
            // Stock was already decremented when credit sale was created
            const mirrorSale = new saleModel({
              customer_name: customerName,
              warehouse_id: new Types.ObjectId(warehouseId),
              created_by: new Types.ObjectId(createdById),
              sale_date: creditSale.sale_date,
              total_amount: creditSale.total_amount,
              source_credit_sale_id: id, // Store as string, not ObjectId
            });
            
            const savedMirrorSale = await mirrorSale.save();
            console.log('[CreditSalesService] ✅ Mirror sale created:', savedMirrorSale._id);
            
            // Create sale items directly without stock operations
            const saleItemModel = this.connection.model('SaleItem');
            for (const item of items) {
              const saleItem = new saleItemModel({
                sale_id: savedMirrorSale._id,
                product_id: item.product_id,
                quantity: item.quantity,
                unit_price: item.unit_price,
              });
              await saleItem.save();
              console.log(`[CreditSalesService]   ✅ Sale item created for product: ${item.product_id}`);
            }
            
            console.log('[CreditSalesService] ✅✅✅ MIRROR SALE CREATION COMPLETE ✅✅✅');
          } else {
            console.log('[CreditSalesService] ⚠️ No items found, cannot create mirror sale');
          }
        }
      } else if (status === 'completed' && !this.salesService) {
        console.log('[CreditSalesService] ⚠️ Status is completed but salesService is not available');
      } else {
        console.log(`[CreditSalesService] Status is "${status}", not creating mirror sale`);
      }
    } catch (e) {
      console.error('[CreditSalesService] ❌ Mirror to Sale failed:', e);
      console.error('[CreditSalesService] Error stack:', e.stack);
      // Do not block status update
    }

    console.log('[CreditSalesService] updateStatus completed, returning saved credit sale');
    return saved;
  }

  async checkAndUpdateStatuses(): Promise<void> {
    const creditSales = await this.findAll();
    const today = new Date();

    for (const creditSale of creditSales) {
      const creditSaleObj: any = creditSale;
      if (creditSaleObj.status === 'active' || creditSaleObj.status === 'pending' || creditSaleObj.status === null) {
        // Check if credit sale is completed
        const totalPaid = await this.calculateTotalPaid(creditSaleObj._id.toString());
        const remaining = Number(creditSaleObj.credit_amount) - Number(totalPaid);
        
        if (remaining <= 0) {
          await this.updateStatus(creditSaleObj._id.toString(), 'completed');
          continue;
        }

        // Check if credit sale is overdue
        if (creditSaleObj.first_payment_date && new Date(creditSaleObj.first_payment_date) < today) {
          const paymentModel = this.connection.model('CreditPayment');
          const payments = await paymentModel.find({ 
            credit_sale_id: creditSaleObj._id 
          })
            .sort({ payment_date: -1 })
            .exec();
            
          const lastPayment = payments.length > 0 ? payments[0] : null;
          const lastPaymentDate = lastPayment ? new Date(lastPayment.payment_date) : new Date(0);
          const daysSinceLastPayment = Math.floor((today.getTime() - lastPaymentDate.getTime()) / (1000 * 60 * 60 * 24));
          
          if (daysSinceLastPayment > 30) { // Overdue after 30 days
            await this.updateStatus(creditSaleObj._id.toString(), 'overdue');
          }
        }
      }
    }
  }

  async getStatusStatistics(): Promise<any> {
    const creditSales = await this.findAll();
    
    const stats = {
      total: creditSales.length,
      pending: 0,
      active: 0,
      completed: 0,
      overdue: 0,
      totalAmount: 0,
      totalPaid: 0,
      totalOutstanding: 0
    } as any;

    for (const creditSale of creditSales) {
      const creditSaleObj: any = creditSale;
      stats[creditSaleObj.status]++;
      stats.totalAmount += Number(creditSaleObj.total_amount);
      
      const totalPaid = await this.calculateTotalPaid(creditSaleObj._id.toString());
      stats.totalPaid += totalPaid;
      stats.totalOutstanding += (Number(creditSaleObj.credit_amount) - totalPaid);
    }

    return stats;
  }

  // Helper method to calculate total paid amount
  private async calculateTotalPaid(creditSaleId: string): Promise<number> {
    const paymentModel = this.connection.model('CreditPayment');
    const result = await paymentModel.aggregate([
      { $match: { credit_sale_id: new Types.ObjectId(creditSaleId) } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]).exec();
    
    return result.length > 0 ? (result[0].total || 0) : 0;
  }

  // Update credit sale method
  async update(id: string, updateCreditSaleDto: any): Promise<CreditSale> {
    await this.creditSaleModel.findByIdAndUpdate(id, updateCreditSaleDto, { new: true }).exec();
    return this.findOne(id);
  }

  // Get products available in a specific warehouse
  async getProductsByWarehouse(warehouseId: string) {
    const productStockModel = this.connection.model('ProductStock');
    const productModel = this.connection.model('Product');
    
    const stocks = await productStockModel.find({
      warehouse_id: new Types.ObjectId(warehouseId),
      quantity: { $gt: 0 }
    }).exec();
    
    const productIds = stocks.map((s: any) => s.product_id);
    const products = await productModel.find({
      _id: { $in: productIds }
    })
      .sort({ name: 1 })
      .exec();
    
    return products.map((product: any) => {
      const productObj = product.toObject();
      const stock = stocks.find((s: any) => s.product_id.toString() === productObj._id.toString());
      return {
        ...productObj,
        stock_quantity: stock ? stock.quantity : 0
      };
    });
  }

  // Validate that all products are from the selected warehouse
  private async validateProductsFromWarehouse(items: any[], warehouseId: string) {
    const productStockModel = this.connection.model('ProductStock');
    
    for (const item of items) {
      const stock = await productStockModel.findOne({
        product_id: new Types.ObjectId(item.product_id),
        warehouse_id: new Types.ObjectId(warehouseId)
      }).exec();
      
      if (!stock) {
        throw new BadRequestException(`Product with ID ${item.product_id} is not available in warehouse ${warehouseId}`);
      }
      
      const availableStock = stock.quantity || 0;
      if (availableStock < item.quantity) {
        throw new BadRequestException(`Insufficient stock for product ID ${item.product_id}. Available: ${availableStock}, Requested: ${item.quantity}`);
      }
      
      console.log(`[CreditSalesService] Product ${item.product_id} validated - Available: ${availableStock}, Requested: ${item.quantity}`);
    }
    
    console.log('[CreditSalesService] All products validated successfully');
  }

  // Calculate total profit from credit sales for a specific year
  async calculateProfitByYear(year: number): Promise<number> {
    try {
      const productModel = this.connection.model('Product');
      
      // Get all credit sales for the specified year
      const creditSales = await this.creditSaleModel.find({
        sale_date: {
          $gte: new Date(year, 0, 1),
          $lt: new Date(year + 1, 0, 1)
        }
      }).exec();

      let totalProfit = 0;

      // For each credit sale, get its items and calculate profit
      for (const creditSale of creditSales) {
        const items = await this.creditSaleItemModel.find({
          credit_sale_id: creditSale._id
        }).exec();

        // For each item, calculate profit
        for (const item of items) {
          const itemObj: any = item.toObject();
          
          // Get product to fetch supplier price
          const product = await productModel.findById(itemObj.product_id).exec();
          
          if (product) {
            const productObj: any = product.toObject();
            const unitPrice = itemObj.unit_price || 0;
            const supplierPrice = productObj.supplier_price || 0;
            const quantity = itemObj.quantity || 0;
            
            const profit = (unitPrice - supplierPrice) * quantity;
            totalProfit += profit;
          }
        }
      }

      return totalProfit;
    } catch (e) {
      console.error('[CreditSalesService] Error calculating profit:', e);
      return 0;
    }
  }
}

