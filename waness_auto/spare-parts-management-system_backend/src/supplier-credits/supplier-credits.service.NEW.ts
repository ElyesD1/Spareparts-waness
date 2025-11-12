import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel, InjectConnection } from '@nestjs/mongoose';
import { Model, Types, Connection, ClientSession } from 'mongoose';
import { SupplierCredit, SupplierCreditDocument, CreditStatus, CreditSourceType } from './supplier-credit.entity';
import { SupplierCreditUsage, SupplierCreditUsageDocument } from './supplier-credit-usage.entity';
import { Purchase } from 'src/purchases/purchase.entity';

@Injectable()
export class SupplierCreditsService {
  constructor(
    @InjectModel(SupplierCredit.name)
    private readonly supplierCreditModel: Model<SupplierCreditDocument>,
    @InjectModel(SupplierCreditUsage.name)
    private readonly supplierCreditUsageModel: Model<SupplierCreditUsageDocument>,
    @InjectModel(Purchase.name)
    private readonly purchaseModel: Model<any>,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  async createManualCredit(
    supplierId: string,
    amount: number,
    notes?: string,
    expiryDate?: Date
  ): Promise<SupplierCredit> {
    const credit = new this.supplierCreditModel({
      supplier_id: new Types.ObjectId(supplierId),
      credit_amount: amount,
      remaining_amount: amount,
      source_type: CreditSourceType.MANUAL_ADJUSTMENT,
      notes,
      expiry_date: expiryDate,
    });

    return credit.save();
  }

  async getAvailableCredits(supplierId: string): Promise<SupplierCredit[]> {
    const credits = await this.supplierCreditModel.find({
      supplier_id: new Types.ObjectId(supplierId),
      status: CreditStatus.ACTIVE,
    })
      .sort({ created_at: 1 }) // Use oldest credits first (FIFO)
      .exec();
      
    return credits.filter(credit => Number(credit.remaining_amount) > 0);
  }

  async getTotalAvailableCredit(supplierId: string): Promise<number> {
    const credits = await this.getAvailableCredits(supplierId);
    return credits.reduce((sum, credit) => sum + Number(credit.remaining_amount), 0);
  }

  async applyCreditsToPurchase(
    purchaseId: string,
    supplierId: string,
    amountToApply: number
  ): Promise<{ appliedAmount: number; remainingPurchaseAmount: number }> {
    const session: ClientSession = await this.connection.startSession();
    session.startTransaction();

    try {
      const purchase = await this.purchaseModel.findById(purchaseId).session(session).exec();
      if (!purchase) {
        throw new NotFoundException(`Purchase with ID ${purchaseId} not found`);
      }

      const purchaseSupplierId = purchase.supplier_id?.toString();
      if (purchaseSupplierId !== supplierId) {
        throw new BadRequestException('Purchase supplier does not match the specified supplier');
      }

      const availableCredits = await this.getAvailableCredits(supplierId);
      let totalApplied = 0;
      let remainingAmount = amountToApply;

      for (const credit of availableCredits) {
        if (remainingAmount <= 0) break;

        const amountToUse = Math.min(Number(credit.remaining_amount), remainingAmount);
        const newRemainingAmount = Number(credit.remaining_amount) - amountToUse;
        
        // Update credit remaining amount
        await this.supplierCreditModel.findByIdAndUpdate(
          (credit as any)._id,
          {
            remaining_amount: newRemainingAmount,
            status: newRemainingAmount <= 0 ? CreditStatus.USED : CreditStatus.ACTIVE,
          },
          { session, new: true }
        ).exec();

        // Record credit usage
        const creditUsage = new this.supplierCreditUsageModel({
          supplier_credit_id: (credit as any)._id,
          purchase_id: new Types.ObjectId(purchaseId),
          amount_used: amountToUse,
        });

        await creditUsage.save({ session });

        totalApplied += amountToUse;
        remainingAmount -= amountToUse;
      }

      // Update purchase with applied credit amount
      await this.purchaseModel.findByIdAndUpdate(
        purchaseId,
        { credit_applied: totalApplied },
        { session, new: true }
      ).exec();

      await session.commitTransaction();

      return {
        appliedAmount: totalApplied,
        remainingPurchaseAmount: amountToApply - totalApplied,
      };
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async autoApplyCreditsToPurchase(purchaseId: string): Promise<{ appliedAmount: number; remainingPurchaseAmount: number }> {
    const purchase = await this.purchaseModel.findById(purchaseId).exec();
    if (!purchase || !purchase.supplier_id) {
      throw new BadRequestException('Purchase not found or has no supplier');
    }

    const supplierId = purchase.supplier_id.toString();
    const availableCredit = await this.getTotalAvailableCredit(supplierId);
    const amountToApply = Math.min(availableCredit, Number(purchase.total_amount));

    if (amountToApply > 0) {
      return this.applyCreditsToPurchase(purchaseId, supplierId, amountToApply);
    }

    return { appliedAmount: 0, remainingPurchaseAmount: Number(purchase.total_amount) };
  }

  async findAll(): Promise<SupplierCredit[]> {
    return this.supplierCreditModel.find()
      .populate('supplier_id')
      .sort({ created_at: -1 })
      .exec();
  }

  async findOne(id: string): Promise<SupplierCredit> {
    const credit = await this.supplierCreditModel.findById(id)
      .populate('supplier_id')
      .exec();

    if (!credit) {
      throw new NotFoundException(`Supplier credit with ID ${id} not found`);
    }

    return credit;
  }

  async findBySupplier(supplierId: string): Promise<SupplierCredit[]> {
    return this.supplierCreditModel.find({ 
      supplier_id: new Types.ObjectId(supplierId) 
    })
      .sort({ created_at: -1 })
      .exec();
  }

  async updateCreditStatus(id: string, status: CreditStatus): Promise<SupplierCredit> {
    await this.supplierCreditModel.findByIdAndUpdate(id, { status }, { new: true }).exec();
    return this.findOne(id);
  }

  async getCreditUsageHistory(creditId: string): Promise<SupplierCreditUsage[]> {
    return this.supplierCreditUsageModel.find({ 
      supplier_credit_id: new Types.ObjectId(creditId) 
    })
      .populate('purchase_id')
      .sort({ used_at: -1 })
      .exec();
  }

  async checkAndUpdateExpiredCredits(): Promise<void> {
    const expiredCredits = await this.supplierCreditModel.find({
      expiry_date: { $lt: new Date() },
      status: CreditStatus.ACTIVE,
    }).exec();

    for (const credit of expiredCredits) {
      await this.supplierCreditModel.findByIdAndUpdate(
        (credit as any)._id,
        { status: CreditStatus.EXPIRED },
        { new: true }
      ).exec();
    }
  }
}
