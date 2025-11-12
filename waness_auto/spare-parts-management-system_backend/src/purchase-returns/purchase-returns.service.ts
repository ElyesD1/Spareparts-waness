import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types, Connection } from 'mongoose';
import { InjectConnection } from '@nestjs/mongoose';
import { PurchaseReturn, PurchaseReturnDocument, ReturnStatus } from './purchase-return.entity';
import { CreatePurchaseReturnDto } from './dto/create-purchase-return.dto';
import { UpdatePurchaseReturnDto } from './dto/update-purchase-return.dto';
import { SupplierCredit, SupplierCreditDocument, CreditSourceType } from '../supplier-credits/supplier-credit.entity';
import { ProductStocksService } from '../product-stocks/product-stocks.service';
import { StockMovementService } from '../stock-movement/stock-movement.service';
import { MovementType } from '../stock-movement/dto/create-stock-movement.dto';

@Injectable()
export class PurchaseReturnsService {
  constructor(
    @InjectModel(PurchaseReturn.name)
    private readonly purchaseReturnModel: Model<PurchaseReturnDocument>,
    @InjectModel(SupplierCredit.name)
    private readonly supplierCreditModel: Model<SupplierCreditDocument>,
    private readonly productStocksService: ProductStocksService,
    private readonly stockMovementService: StockMovementService,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  async create(createPurchaseReturnDto: CreatePurchaseReturnDto, userId: string): Promise<PurchaseReturn> {
    const session = await this.connection.startSession();
    session.startTransaction();

    try {
      // Calculate total
      const totalAmount = createPurchaseReturnDto.items.reduce((sum, item) => sum + item.total_price, 0);

      // Create PurchaseReturn
      const purchaseReturn = new this.purchaseReturnModel({
        supplier_id: new Types.ObjectId(createPurchaseReturnDto.supplier_id),
        warehouse_id: new Types.ObjectId(createPurchaseReturnDto.warehouse_id),
        reason: createPurchaseReturnDto.reason,
        created_by: new Types.ObjectId(userId),
        total_amount: totalAmount,
        status: ReturnStatus.PENDING,
      });

      const savedPurchaseReturn = await purchaseReturn.save({ session });

      // Insert items
      for (const item of createPurchaseReturnDto.items) {
        await this.connection.db!.collection('purchasereturnitems').insertOne(
          {
            purchase_return_id: savedPurchaseReturn._id,
            product_id: new Types.ObjectId(item.product_id),
            quantity: item.quantity,
            unit_price: item.unit_price,
            total_price: item.total_price,
          },
          { session }
        );
      }

      await session.commitTransaction();

      // Return the complete purchase return with relations
      return this.findOne((savedPurchaseReturn._id as Types.ObjectId).toString());
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async approve(id: string, userId: string): Promise<PurchaseReturn> {
    const purchaseReturn = await this.findOne(id);

    if (purchaseReturn.status !== ReturnStatus.PENDING) {
      throw new BadRequestException('Purchase return can only be approved when status is pending');
    }

    const session = await this.connection.startSession();
    session.startTransaction();

    try {
      // Update status
      await this.purchaseReturnModel.findByIdAndUpdate(
        id,
        { 
          status: ReturnStatus.APPROVED,
          approved_by: new Types.ObjectId(userId),
          approved_at: new Date()
        },
        { session }
      ).exec();

      // Get items
      const items = await this.connection.db!.collection('purchasereturnitems')
        .find({ purchase_return_id: new Types.ObjectId(id) })
        .toArray();

      // Decrement stock and create movements for each item
      for (const item of items) {
        await this.productStocksService.decrementStock(
          item.product_id.toString(),
          purchaseReturn.warehouse_id.toString(),
          item.quantity
        );

        await this.stockMovementService.create({
          product_id: item.product_id.toString(),
          quantity: item.quantity,
          movement_type: MovementType.RETURN,
          from_warehouse_id: purchaseReturn.warehouse_id.toString(),
          user_id: userId,
          note: `Purchase return: ${purchaseReturn.reason}`,
        });
      }

      // Create supplier credit
      const credit = new this.supplierCreditModel({
        supplier_id: purchaseReturn.supplier_id,
        amount: purchaseReturn.total_amount,
        remaining_amount: purchaseReturn.total_amount,
        source_type: CreditSourceType.PURCHASE_RETURN,
        source_id: new Types.ObjectId(id),
        created_by: new Types.ObjectId(userId),
      });

      await credit.save({ session });

      await session.commitTransaction();

      return this.findOne(id);
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      session.endSession();
    }
  }

  async reject(id: string, userId: string, reason: string): Promise<PurchaseReturn> {
    const purchaseReturn = await this.findOne(id);

    if (purchaseReturn.status !== ReturnStatus.PENDING) {
      throw new BadRequestException('Purchase return can only be rejected when status is pending');
    }

    await this.purchaseReturnModel.findByIdAndUpdate(id, {
      status: ReturnStatus.REJECTED,
      approved_by: new Types.ObjectId(userId),
      approved_at: new Date(),
      reason: `${purchaseReturn.reason} - Rejected: ${reason}`
    }).exec();

    return this.findOne(id);
  }

  async findAll(): Promise<PurchaseReturn[]> {
    const returns = await this.purchaseReturnModel
      .find()
      .populate('supplier_id')
      .populate('warehouse_id')
      .populate('created_by')
      .populate('approved_by')
      .sort({ created_at: -1 })
      .exec();

    // Fetch items for each return
    const returnsWithItems = await Promise.all(
      returns.map(async (purchaseReturn) => {
        const items = await this.connection.db!.collection('purchasereturnitems')
          .find({ purchase_return_id: purchaseReturn._id })
          .toArray();

        return {
          ...purchaseReturn.toObject(),
          items
        };
      })
    );

    return returnsWithItems;
  }

  async findOne(id: string): Promise<any> {
    const purchaseReturn = await this.purchaseReturnModel
      .findById(id)
      .populate('supplier_id')
      .populate('warehouse_id')
      .populate('created_by')
      .populate('approved_by')
      .exec();

    if (!purchaseReturn) {
      throw new NotFoundException(`Purchase return with ID ${id} not found`);
    }

    const items = await this.connection.db!.collection('purchasereturnitems')
      .find({ purchase_return_id: new Types.ObjectId(id) })
      .toArray();

    return {
      ...purchaseReturn.toObject(),
      items: items.map(item => ({
        ...item,
        purchase_return_id: item.purchase_return_id.toString(),
        product_id: item.product_id.toString(),
      }))
    };
  }

  async findBySupplier(supplierId: string): Promise<PurchaseReturn[]> {
    return this.purchaseReturnModel
      .find({ supplier_id: new Types.ObjectId(supplierId) })
      .populate('warehouse_id')
      .populate('created_by')
      .populate('approved_by')
      .sort({ created_at: -1 })
      .exec();
  }

  async update(id: string, updatePurchaseReturnDto: UpdatePurchaseReturnDto): Promise<PurchaseReturn> {
    const purchaseReturn = await this.findOne(id);

    if (purchaseReturn.status !== ReturnStatus.PENDING) {
      throw new BadRequestException('Can only update purchase return when status is pending');
    }

    await this.purchaseReturnModel.findByIdAndUpdate(id, updatePurchaseReturnDto).exec();

    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    const purchaseReturn = await this.findOne(id);

    if (purchaseReturn.status === ReturnStatus.APPROVED) {
      throw new BadRequestException('Cannot delete an approved purchase return');
    }

    // Delete items first
    await this.connection.db!.collection('purchasereturnitems').deleteMany({
      purchase_return_id: new Types.ObjectId(id)
    });

    // Delete the return
    await this.purchaseReturnModel.findByIdAndDelete(id).exec();
  }
}

