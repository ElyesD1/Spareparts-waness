import { Injectable, NotFoundException, BadRequestException, Optional } from '@nestjs/common';
import { InjectModel, InjectConnection } from '@nestjs/mongoose';
import { Model, Types, Connection, ClientSession } from 'mongoose';
import { CreditSale, CreditSaleDocument } from './credit-sale.entity';
import { CreateCreditSaleDto } from './dto/create-credit-sale.dto';
import { CustomersService } from '../customers/customers.service';
import { ProductStocksService } from '../product-stocks/product-stocks.service';
import { CreditSaleItem, CreditSaleItemDocument } from '../credit-sale-items/credit-sale-item.entity';
import { SalesService } from '../sales/sales.service';

@Injectable()
export class CreditSalesService {
  constructor(
    @InjectModel(CreditSale.name)
    private creditSaleModel: Model<CreditSaleDocument>,
    @InjectModel(CreditSaleItem.name)
    private creditSaleItemModel: Model<CreditSaleItemDocument>,
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

    const session: ClientSession = await this.connection.startSession();
    session.startTransaction();

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

      const savedCreditSale = await creditSale.save({ session });
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

        await creditSaleItem.save({ session });
        console.log('Credit sale item saved successfully');
      }

      await session.commitTransaction();
      console.log('=== BACKEND: CREDIT SALE CREATION SUCCESS ===');
      console.log('Transaction committed successfully');
      
      // Update customer balance and product stocks AFTER the transaction is committed
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
      await session.abortTransaction();
      console.log('Transaction rolled back');
      throw error;
    } finally {
      session.endSession();
      console.log('Session ended');
    }
  }

  async findAll(): Promise<CreditSale[]> {
    return this.creditSaleModel.find()
      .populate('customer_id')
      .populate('warehouse_id')
      .populate('created_by')
      .sort({ createdAt: -1 })
      .exec();
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
    const validStatuses = ['pending', 'active', 'completed', 'overdue'];
    if (!validStatuses.includes(status)) {
      throw new BadRequestException(`Invalid status. Must be one of: ${validStatuses.join(', ')}`);
    }

    await this.creditSaleModel.findByIdAndUpdate(id, { status }, { new: true }).exec();
    
    const saved = await this.findOne(id);

    // If a credit sale becomes completed (paid), mirror it as a normal Sale
    try {
      if (status === 'completed' && this.salesService) {
        const saleModel = this.connection.model('Sale');
        const existingMirror = await saleModel.findOne({ 
          source_credit_sale_id: new Types.ObjectId(id) 
        }).exec();
        
        if (!existingMirror) {
          const items = await this.creditSaleItemModel.find({ 
            credit_sale_id: new Types.ObjectId(id) 
          }).exec();
          
          if (items.length > 0) {
            const creditSale: any = saved;
            const customerModel = this.connection.model('Customer');
            const customer = await customerModel.findById(creditSale.customer_id).exec();
            const customerName = customer?.name || `Customer#${creditSale.customer_id}`;
            
            const saleDto: any = {
              customer_name: customerName,
              warehouse_id: creditSale.warehouse_id,
              sale_date: creditSale.sale_date,
              total_amount: creditSale.total_amount,
              created_by: creditSale.created_by,
              items: items.map((item: any) => ({
                product_id: item.product_id.toString(),
                quantity: item.quantity,
                unit_price: item.unit_price,
              })),
            };
            
            const mirrored: any = await this.salesService.create(saleDto, creditSale.created_by.toString());
            // Persist linkage
            const mirroredId = mirrored._id || mirrored.id;
            await saleModel.findByIdAndUpdate(
              mirroredId,
              { source_credit_sale_id: new Types.ObjectId(id) },
              { new: true }
            ).exec();
          }
        }
      }
    } catch (e) {
      console.error('[CreditSalesService] Mirror to Sale failed:', e);
      // Do not block status update
    }

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
}

