import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types, Connection } from 'mongoose';
import { InjectConnection } from '@nestjs/mongoose';
import { ProductTransfer, ProductTransferDocument, TransferStatus, TransferPriority } from './product-transfer.entity';
import { CreateProductTransferDto } from './dto/create-product-transfer.dto';
import { UpdateProductTransferDto, ApproveTransferDto, RejectTransferDto, ProcessTransferDto } from './dto/update-product-transfer.dto';
import { ProductStocksService } from '../product-stocks/product-stocks.service';
import { StockMovementService } from '../stock-movement/stock-movement.service';
import { MovementType } from '../stock-movement/dto/create-stock-movement.dto';

@Injectable()
export class ProductTransfersService {
  constructor(
    @InjectModel(ProductTransfer.name)
    private readonly productTransferModel: Model<ProductTransferDocument>,
    private readonly productStocksService: ProductStocksService,
    private readonly stockMovementService: StockMovementService,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  async create(createProductTransferDto: CreateProductTransferDto): Promise<ProductTransfer> {
    // Validate that source and destination warehouses are different
    if (createProductTransferDto.from_warehouse_id === createProductTransferDto.to_warehouse_id) {
      throw new BadRequestException('Source and destination warehouses must be different');
    }

    // Check if product exists and has sufficient stock in source warehouse
    const stock = await this.productStocksService.checkStockAvailability(
      createProductTransferDto.product_id,
      createProductTransferDto.from_warehouse_id,
      createProductTransferDto.quantity
    );

    if (!stock) {
      throw new BadRequestException('Insufficient stock in source warehouse');
    }

    const productTransfer = new this.productTransferModel({
      ...createProductTransferDto,
      product_id: new Types.ObjectId(createProductTransferDto.product_id),
      from_warehouse_id: new Types.ObjectId(createProductTransferDto.from_warehouse_id),
      to_warehouse_id: new Types.ObjectId(createProductTransferDto.to_warehouse_id),
      requested_by: new Types.ObjectId(createProductTransferDto.requested_by),
    });

    return (await productTransfer.save()).toObject();
  }

  async findAll(): Promise<any[]> {
    const transfers = await this.productTransferModel
      .find()
      .populate('product_id')
      .populate('from_warehouse_id')
      .populate('to_warehouse_id')
      .populate('requested_by')
      .populate('approved_by')
      .populate('processed_by')
      .sort({ created_at: -1 })
      .lean()
      .exec();

    return transfers.map(transfer => ({
      ...transfer,
      product_name: (transfer.product_id as any)?.name || 'Unknown Product',
      product_reference: (transfer.product_id as any)?.reference_code || '',
      from_warehouse_name: (transfer.from_warehouse_id as any)?.name || 'Unknown Warehouse',
      to_warehouse_name: (transfer.to_warehouse_id as any)?.name || 'Unknown Warehouse',
      requested_by_name: (transfer.requested_by as any)?.name || 'Unknown User',
      approved_by_name: (transfer.approved_by as any)?.name || '',
      processed_by_name: (transfer.processed_by as any)?.name || '',
    }));
  }

  async findByWarehouse(warehouseId: string): Promise<any[]> {
    const objectId = new Types.ObjectId(warehouseId);
    const transfers = await this.productTransferModel
      .find({
        $or: [
          { from_warehouse_id: objectId },
          { to_warehouse_id: objectId }
        ]
      })
      .populate('product_id')
      .populate('from_warehouse_id')
      .populate('to_warehouse_id')
      .populate('requested_by')
      .populate('approved_by')
      .populate('processed_by')
      .sort({ created_at: -1 })
      .lean()
      .exec();

    return transfers.map(transfer => ({
      ...transfer,
      product_name: (transfer.product_id as any)?.name || 'Unknown Product',
      product_reference: (transfer.product_id as any)?.reference_code || '',
      from_warehouse_name: (transfer.from_warehouse_id as any)?.name || 'Unknown Warehouse',
      to_warehouse_name: (transfer.to_warehouse_id as any)?.name || 'Unknown Warehouse',
      requested_by_name: (transfer.requested_by as any)?.name || 'Unknown User',
      approved_by_name: (transfer.approved_by as any)?.name || '',
      processed_by_name: (transfer.processed_by as any)?.name || '',
    }));
  }

  async findOne(id: string): Promise<ProductTransfer> {
    const transfer = await this.productTransferModel
      .findById(id)
      .populate('product_id')
      .populate('from_warehouse_id')
      .populate('to_warehouse_id')
      .populate('requested_by')
      .populate('approved_by')
      .populate('processed_by')
      .exec();

    if (!transfer) {
      throw new NotFoundException(`Product transfer with ID ${id} not found`);
    }

    return transfer.toObject();
  }

  async update(id: string, updateProductTransferDto: UpdateProductTransferDto): Promise<ProductTransfer> {
    const transfer = await this.productTransferModel.findById(id).exec();
    if (!transfer) {
      throw new NotFoundException(`Product transfer with ID ${id} not found`);
    }

    Object.assign(transfer, updateProductTransferDto);
    await transfer.save();
    return this.findOne(id);
  }

  async approve(id: string, approveDto: ApproveTransferDto): Promise<ProductTransfer> {
    const transfer = await this.productTransferModel.findById(id).exec();
    if (!transfer) {
      throw new NotFoundException(`Product transfer with ID ${id} not found`);
    }

    // If already approved/completed, return success response
    if (transfer.status === TransferStatus.APPROVED || transfer.status === TransferStatus.COMPLETED) {
      return transfer.toObject();
    }

    if (transfer.status !== TransferStatus.PENDING) {
      throw new BadRequestException('Only pending transfers can be approved');
    }

    // Re-check stock availability at approval time
    const hasStock = await this.productStocksService.checkStockAvailability(
      transfer.product_id.toString(),
      transfer.from_warehouse_id.toString(),
      transfer.quantity
    );

    if (!hasStock.available) {
      throw new BadRequestException(`Insufficient stock in source warehouse: ${hasStock.message}`);
    }

    try {
      // Update transfer status to approved
      transfer.status = TransferStatus.APPROVED;
      transfer.approved_by = new Types.ObjectId(approveDto.approved_by);
      transfer.approved_at = new Date();
      if (approveDto.notes) {
        transfer.notes = approveDto.notes;
      }
      await transfer.save();

      // Immediately process the transfer (move stock)
      transfer.status = TransferStatus.IN_TRANSIT;
      transfer.processed_by = new Types.ObjectId(approveDto.approved_by); // Same user processes
      transfer.processed_at = new Date();
      await transfer.save();

      // Update stock levels
      await this.productStocksService.decrementStock(
        transfer.product_id.toString(),
        transfer.from_warehouse_id.toString(),
        transfer.quantity
      );

      await this.productStocksService.incrementStock(
        transfer.product_id.toString(),
        transfer.to_warehouse_id.toString(),
        transfer.quantity
      );

      // Create stock movement record
      await this.stockMovementService.create({
        product_id: transfer.product_id.toString(),
        from_warehouse_id: transfer.from_warehouse_id.toString(),
        to_warehouse_id: transfer.to_warehouse_id.toString(),
        quantity: transfer.quantity,
        movement_type: MovementType.TRANSFER,
        user_id: approveDto.approved_by,
        note: `Transfer from warehouse ${transfer.from_warehouse_id} to warehouse ${transfer.to_warehouse_id}`,
      });

      // Auto-complete the transfer
      transfer.status = TransferStatus.COMPLETED;
      await transfer.save();

      return transfer.toObject();
    } catch (error) {
      throw error;
    }
  }

  async reject(id: string, rejectDto: RejectTransferDto): Promise<ProductTransfer> {
    const transfer = await this.productTransferModel.findById(id).exec();
    if (!transfer) {
      throw new NotFoundException(`Product transfer with ID ${id} not found`);
    }

    if (transfer.status !== TransferStatus.PENDING) {
      throw new BadRequestException('Only pending transfers can be rejected');
    }

    transfer.status = TransferStatus.REJECTED;
    transfer.approved_by = new Types.ObjectId(rejectDto.approved_by);
    transfer.approved_at = new Date();
    if (rejectDto.reason) {
      transfer.notes = rejectDto.reason;
    }

    await transfer.save();
    return this.findOne(id);
  }

  async process(id: string, processDto: ProcessTransferDto): Promise<ProductTransfer> {
    const transfer = await this.productTransferModel.findById(id).exec();
    if (!transfer) {
      throw new NotFoundException(`Product transfer with ID ${id} not found`);
    }

    if (transfer.status !== TransferStatus.APPROVED) {
      throw new BadRequestException('Only approved transfers can be processed');
    }

    try {
      // Update transfer status
      transfer.status = TransferStatus.IN_TRANSIT;
      transfer.processed_by = new Types.ObjectId(processDto.processed_by);
      transfer.processed_at = new Date();
      if (processDto.notes) {
        transfer.notes = processDto.notes;
      }
      await transfer.save();

      // Update stock levels
      await this.productStocksService.decrementStock(
        transfer.product_id.toString(),
        transfer.from_warehouse_id.toString(),
        transfer.quantity
      );

      await this.productStocksService.incrementStock(
        transfer.product_id.toString(),
        transfer.to_warehouse_id.toString(),
        transfer.quantity
      );

      // Create stock movement record
      await this.stockMovementService.create({
        product_id: transfer.product_id.toString(),
        from_warehouse_id: transfer.from_warehouse_id.toString(),
        to_warehouse_id: transfer.to_warehouse_id.toString(),
        quantity: transfer.quantity,
        movement_type: MovementType.TRANSFER,
        user_id: processDto.processed_by,
        note: `Transfer from warehouse ${transfer.from_warehouse_id} to warehouse ${transfer.to_warehouse_id}`,
      });

      return transfer.toObject();
    } catch (error) {
      throw error;
    }
  }

  async complete(id: string): Promise<ProductTransfer> {
    const transfer = await this.productTransferModel.findById(id).exec();
    if (!transfer) {
      throw new NotFoundException(`Product transfer with ID ${id} not found`);
    }

    if (transfer.status !== TransferStatus.IN_TRANSIT) {
      throw new BadRequestException('Only in-transit transfers can be completed');
    }

    transfer.status = TransferStatus.COMPLETED;
    await transfer.save();
    return this.findOne(id);
  }

  async cancel(id: string, userId: string): Promise<ProductTransfer> {
    const transfer = await this.productTransferModel.findById(id).exec();
    if (!transfer) {
      throw new NotFoundException(`Product transfer with ID ${id} not found`);
    }

    if (transfer.status === TransferStatus.COMPLETED) {
      throw new BadRequestException('Cannot cancel completed transfers');
    }

    // If transfer was in transit, we need to reverse stock movements
    if (transfer.status === TransferStatus.IN_TRANSIT) {
      try {
        // Reverse stock movements
        await this.productStocksService.incrementStock(
          transfer.product_id.toString(),
          transfer.from_warehouse_id.toString(),
          transfer.quantity
        );

        await this.productStocksService.decrementStock(
          transfer.product_id.toString(),
          transfer.to_warehouse_id.toString(),
          transfer.quantity
        );

        // Create reversal movement records
        await this.stockMovementService.create({
          product_id: transfer.product_id.toString(),
          to_warehouse_id: transfer.from_warehouse_id.toString(),
          quantity: transfer.quantity,
          movement_type: MovementType.ADJUSTMENT,
          user_id: userId,
          note: `Transfer cancellation - returned from ${transfer.to_warehouse_id}`,
        });

        await this.stockMovementService.create({
          product_id: transfer.product_id.toString(),
          from_warehouse_id: transfer.to_warehouse_id.toString(),
          quantity: transfer.quantity,
          movement_type: MovementType.ADJUSTMENT,
          user_id: userId,
          note: `Transfer cancellation - returned to ${transfer.from_warehouse_id}`,
        });

        transfer.status = TransferStatus.CANCELLED;
        await transfer.save();

        return transfer.toObject();
      } catch (error) {
        throw error;
      }
    } else {
      // Just update status for non-processed transfers
      transfer.status = TransferStatus.CANCELLED;
      await transfer.save();
      return this.findOne(id);
    }
  }

  async remove(id: string): Promise<void> {
    const transfer = await this.productTransferModel.findById(id).exec();
    if (!transfer) {
      throw new NotFoundException(`Product transfer with ID ${id} not found`);
    }

    // Only allow deletion of pending or rejected transfers
    if (![TransferStatus.PENDING, TransferStatus.REJECTED, TransferStatus.CANCELLED].includes(transfer.status)) {
      throw new BadRequestException('Can only delete pending, rejected, or cancelled transfers');
    }

    await this.productTransferModel.findByIdAndDelete(id).exec();
  }
}

