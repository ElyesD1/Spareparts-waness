import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types, Connection } from 'mongoose';
import { InjectConnection } from '@nestjs/mongoose';
import { CreditPayment, CreditPaymentDocument } from './credit-payment.entity';
import { CreateCreditPaymentDto } from './dto/create-credit-payment.dto';
import { CreditSalesService } from '../credit-sales/credit-sales.service';
import { CustomersService } from '../customers/customers.service';

@Injectable()
export class CreditPaymentsService {
  constructor(
    @InjectModel(CreditPayment.name)
    private creditPaymentModel: Model<CreditPaymentDocument>,
    private creditSalesService: CreditSalesService,
    private customersService: CustomersService,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  async create(createCreditPaymentDto: CreateCreditPaymentDto, userId: string): Promise<CreditPayment> {
    console.log('=== PAYMENT CREATION START ===');
    console.log('Creating credit payment:', createCreditPaymentDto);
    console.log('User ID:', userId);
    
    try {
      // Normalize field names to handle both camelCase and snake_case
      const normalizedDto = this.normalizePaymentData(createCreditPaymentDto);
      console.log('Normalized payment data:', normalizedDto);
      
      // Validate required fields
      if (!normalizedDto.credit_sale_id) {
        throw new Error('credit_sale_id is required but was not provided');
      }
      
      if (!normalizedDto.amount) {
        throw new Error('amount is required but was not provided');
      }
      
      // Direct database check to verify credit sale exists
      const creditSaleExists = await this.connection.db!.collection('credit_sales').findOne({
        _id: new Types.ObjectId(normalizedDto.credit_sale_id)
      });
      
      if (!creditSaleExists) {
        console.error(`Credit sale ID ${normalizedDto.credit_sale_id} does not exist in database`);
        throw new Error(`Credit sale with ID ${normalizedDto.credit_sale_id} does not exist`);
      }
      
      console.log('Credit sale validation passed:', creditSaleExists);
      
      // Create and save the payment using Mongoose
      const payment = new this.creditPaymentModel({
        credit_sale_id: new Types.ObjectId(normalizedDto.credit_sale_id),
        received_by: new Types.ObjectId(userId),
        amount: normalizedDto.amount,
        payment_date: normalizedDto.payment_date ? new Date(normalizedDto.payment_date) : new Date(),
        payment_method: normalizedDto.payment_method || 'cash',
        reference_number: normalizedDto.reference_number,
        notes: normalizedDto.notes || ''
      });
      
      console.log('Payment object created:', payment);
      
      const savedPayment = await payment.save();
      console.log('Payment saved successfully:', savedPayment);

      // Post-commit side effects (best-effort; do not block payment creation)
      (async () => {
        try {
          console.log('[PAYMENT] Starting post-payment processing...');
          
          // Update customer balance
          await this.customersService.updateBalance(creditSaleExists.customer_id.toString(), -normalizedDto.amount);
          console.log('[PAYMENT] Customer balance updated');
          
          // Update credit sale status if needed
          const totalPaid = await this.getTotalPaid(normalizedDto.credit_sale_id);
          const downPayment = Number(creditSaleExists.down_payment || 0);
          const creditAmount = Number(creditSaleExists.credit_amount || 0);
          const remaining = creditAmount - totalPaid;
          
          console.log('[PAYMENT] Payment calculation:');
          console.log(`  - Credit amount: ${creditAmount}`);
          console.log(`  - Down payment: ${downPayment}`);
          console.log(`  - Total installment payments: ${totalPaid}`);
          console.log(`  - Remaining balance: ${remaining}`);
          
          if (remaining <= 0.01) {
            console.log('[PAYMENT] ✅ Credit sale is fully paid! Updating status to completed...');
            const result = await this.creditSalesService.updateStatus(normalizedDto.credit_sale_id, 'completed');
            console.log('[PAYMENT] ✅ Credit sale status updated to completed:', result);
            console.log('[PAYMENT] ✅ Mirror sale should now be created and visible in sales screen');
          } else {
            console.log(`[PAYMENT] ⏳ Still has remaining balance: ${remaining.toFixed(2)} DNT`);
          }
        } catch (err) {
          console.error('[PAYMENT] ❌ Side effect error (non-blocking):', err);
          console.error('[PAYMENT] Error stack:', err.stack);
        }
      })();
      
      return savedPayment.toObject();
    } catch (error) {
      console.error('Payment creation error:', error);
      throw error;
    }
  }

  async findAll(): Promise<CreditPayment[]> {
    return this.creditPaymentModel
      .find()
      .populate('creditSale_id')
      .populate('receivedBy_id')
      .exec();
  }

  async findOne(id: string): Promise<CreditPayment> {
    const payment = await this.creditPaymentModel
      .findById(id)
      .populate('creditSale_id')
      .populate('receivedBy_id')
      .exec();
      
    if (!payment) {
      throw new NotFoundException(`Credit payment with ID ${id} not found`);
    }
    
    return payment.toObject();
  }

  async findByCreditSale(creditSaleId: string): Promise<CreditPayment[]> {
    return this.creditPaymentModel
      .find({ credit_sale_id: new Types.ObjectId(creditSaleId) })
      .populate('received_by')
      .sort({ payment_date: -1 })
      .exec();
  }

  async getTotalPaid(creditSaleId: string): Promise<number> {
    const result = await this.creditPaymentModel.aggregate([
      { $match: { credit_sale_id: new Types.ObjectId(creditSaleId) } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]).exec();
    
    return result.length > 0 ? result[0].total : 0;
  }

  async remove(id: string): Promise<void> {
    const payment = await this.creditPaymentModel.findById(id).exec();
    
    if (!payment) {
      throw new NotFoundException(`Credit payment with ID ${id} not found`);
    }
    
    // Restore customer balance before deleting
    const creditSale = await this.connection.db!.collection('creditsales').findOne({
      _id: payment.credit_sale_id
    });
    
    if (creditSale) {
      await this.customersService.updateBalance(creditSale.customer_id.toString(), payment.amount);
    }
    
    await this.creditPaymentModel.findByIdAndDelete(id).exec();
  }

  /**
   * Normalize payment data to handle both camelCase and snake_case field names
   */
  private normalizePaymentData(dto: CreateCreditPaymentDto): any {
    return {
      credit_sale_id: dto.credit_sale_id || (dto as any).creditSaleId,
      amount: dto.amount,
      payment_date: dto.payment_date || (dto as any).paymentDate,
      payment_method: dto.payment_method || (dto as any).paymentMethod,
      reference_number: dto.reference_number || (dto as any).referenceNumber,
      notes: dto.notes
    };
  }
}

