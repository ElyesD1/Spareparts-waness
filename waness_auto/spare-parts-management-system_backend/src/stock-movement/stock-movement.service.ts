import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { StockMovement, StockMovementDocument } from './stock-movement.entity';
import { CreateStockMovementDto, MovementType } from './dto/create-stock-movement.dto';
import { UpdateStockMovementDto } from './dto/update-stock-movement.dto';

@Injectable()
export class StockMovementService {
  constructor(
    @InjectModel(StockMovement.name)
    private readonly model: Model<StockMovementDocument>,
  ) {}

  async create(createStockMovementDto: CreateStockMovementDto) {
    if (!createStockMovementDto.user_id) {
      throw new Error('StockMovement.user_id is required');
    }
    
    // Add unique identifier to prevent duplicates
    const uniqueId = `${createStockMovementDto.product_id}_${createStockMovementDto.user_id}_${Date.now()}`;
    console.log(`[StockMovementService] 🆔 Creating stock movement with unique ID: ${uniqueId}`);
    console.log('[StockMovementService] 📊 Data:', createStockMovementDto);
    
    try {
      // Check if this exact movement already exists to prevent duplicates
      const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
      
      const existingCheck = await this.model.findOne({
        product_id: new Types.ObjectId(createStockMovementDto.product_id),
        movement_type: createStockMovementDto.movement_type,
        user_id: new Types.ObjectId(createStockMovementDto.user_id),
        quantity: createStockMovementDto.quantity,
        created_at: { $gt: fiveMinutesAgo }
      }).exec();
      
      if (existingCheck) {
        console.log(`[StockMovementService] ⚠️  Recent duplicate detected! Movement already exists with ID: ${(existingCheck as any)._id}`);
        console.log(`[StockMovementService] 🚫 Skipping creation to prevent duplication`);
        return {
          id: (existingCheck as any)._id.toString(),
          ...createStockMovementDto,
          created_at: new Date(),
          duplicate_prevented: true
        };
      }
      
      console.log(`[StockMovementService] 💾 Inserting new stock movement`);
      
      // Convert IDs to ObjectId
      const movementData: any = {
        product_id: new Types.ObjectId(createStockMovementDto.product_id),
        user_id: new Types.ObjectId(createStockMovementDto.user_id),
        quantity: createStockMovementDto.quantity,
        movement_type: createStockMovementDto.movement_type,
        note: createStockMovementDto.note || '',
        created_at: new Date()
      };
      
      if (createStockMovementDto.from_warehouse_id) {
        movementData.from_warehouse_id = new Types.ObjectId(createStockMovementDto.from_warehouse_id);
      }
      
      if (createStockMovementDto.to_warehouse_id) {
        movementData.to_warehouse_id = new Types.ObjectId(createStockMovementDto.to_warehouse_id);
      }
      
      const created = new this.model(movementData);
      const result = await created.save();
      
      console.log(`[StockMovementService] ✅ Stock movement created successfully with ID: ${(result as any)._id}`);
      
      // Return minimal payload (no UI concerns)
      return {
        id: (result as any)._id.toString(),
        ...createStockMovementDto,
        created_at: result.created_at,
      };
      
    } catch (error) {
      console.error(`[StockMovementService] ❌ Error creating stock movement:`, error);
      throw new Error(`Failed to create stock movement: ${error.message}`);
    }
  }

  async findAll() {
    try {
      const movements = await this.model.find()
        .populate('product_id')
        .populate('from_warehouse_id')
        .populate('to_warehouse_id')
        .populate('user_id')
        .sort({ created_at: -1 })
        .exec();
        
      console.log(`[StockMovementService] Found ${movements.length} stock movements`);
      
      // Map to plain data object; leave presentation to frontend
      return movements.map(movement => {
        const movementObj: any = movement.toObject();
        
        // Derive an effective type for frontend display
        const isSaleByNote = typeof movementObj.note === 'string' && movementObj.note.toLowerCase().startsWith('vente');
        const effectiveType = isSaleByNote ? 'sale' : movementObj.movement_type;
        
        return {
          id: movementObj._id.toString(),
          product_id: movementObj.product_id?._id?.toString() || null,
          product_name: movementObj.product_id?.name || 'Unknown Product',
          product_reference: movementObj.product_id?.reference_code || '',
          product_brand: movementObj.product_id?.brand || '',
          product_category: movementObj.product_id?.category || '',
          from_warehouse_id: movementObj.from_warehouse_id?._id?.toString() || null,
          from_warehouse_name: movementObj.from_warehouse_id?.name || 'Unknown Warehouse',
          to_warehouse_id: movementObj.to_warehouse_id?._id?.toString() || null,
          to_warehouse_name: movementObj.to_warehouse_id?.name || 'Unknown Warehouse',
          user_id: movementObj.user_id?._id?.toString() || null,
          user_name: movementObj.user_id?.name || 'Unknown User',
          user_role: movementObj.user_id?.role || '',
          quantity: movementObj.quantity,
          movement_type: effectiveType as any,
          created_at: movementObj.created_at,
          note: movementObj.note,
        };
      });
    } catch (error) {
      console.error('[StockMovementService] Error finding all stock movements:', error);
      throw new Error(`Failed to fetch stock movements: ${error.message}`);
    }
  }

  async findOne(id: string) {
    return this.model.findById(id).exec();
  }

  async update(id: string, updateStockMovementDto: UpdateStockMovementDto) {
    await this.model.findByIdAndUpdate(id, updateStockMovementDto, { new: true }).exec();
    return this.findOne(id);
  }

  async remove(id: string) {
    return this.model.findByIdAndDelete(id).exec();
  }
}

