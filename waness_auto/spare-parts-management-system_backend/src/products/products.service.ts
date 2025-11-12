import { Injectable, NotFoundException, ConflictException } from "@nestjs/common";
import { InjectModel } from "@nestjs/mongoose";
import { Model, Types } from "mongoose";
import { Product, ProductDocument } from "./products.entity";

@Injectable()
export class ProductsService {
  constructor(
    @InjectModel(Product.name)
    private readonly productModel: Model<ProductDocument>
  ) {}

  async create(data: Partial<Product>) {
    const product = new this.productModel(data);
    return product.save();
  }

  async findAll(includeDeleted = false) {
    if (includeDeleted) {
      return this.productModel.find().lean().exec();
    }
    return this.productModel.find({ deletedAt: null }).lean().exec();
  }

  async findOne(id: string) {
    const product = await this.productModel.findById(id).lean().exec();
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  async findByBarcode(barcode: string) {
    return this.productModel.findOne({ barcode }).lean().exec();
  }

  async findByWarehouse(warehouseId: string) {
    const warehouseObjectId = new Types.ObjectId(warehouseId);
    
    // Using MongoDB aggregation to join products with stock
    return this.productModel.aggregate([
      {
        $lookup: {
          from: 'product_stocks',
          localField: '_id',
          foreignField: 'product_id',
          as: 'stocks'
        }
      },
      {
        $unwind: '$stocks'
      },
      {
        $match: {
          'stocks.warehouse_id': warehouseObjectId,
          'stocks.quantity': { $gt: 0 }
        }
      },
      {
        $addFields: {
          stock_quantity: '$stocks.quantity'
        }
      },
      {
        $project: {
          stocks: 0
        }
      },
      {
        $sort: { name: 1 }
      }
    ]).exec();
  }

  async update(id: string, data: Partial<Product>) {
    const product = await this.productModel
      .findByIdAndUpdate(id, data, { new: true })
      .exec();
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  // Hard delete
  async remove(id: string, force = false) {
    try {
      // Check if product exists
      const product = await this.findOne(id);
      const productObjectId = new Types.ObjectId(id);
      
      if (!force) {
        // Check for dependencies before deletion
        const stockCount = await this.productModel.db.collection('product_stocks')
          .countDocuments({ product_id: productObjectId });
        
        if (stockCount > 0) {
          throw new ConflictException('Cannot delete product: Product has stock records. Please remove all stock entries first.');
        }

        const purchaseItemCount = await this.productModel.db.collection('purchase_items')
          .countDocuments({ product_id: productObjectId });
        
        if (purchaseItemCount > 0) {
          throw new ConflictException('Cannot delete product: Product is referenced in purchase records. Please remove purchase records first.');
        }

        const saleItemCount = await this.productModel.db.collection('sale_items')
          .countDocuments({ product_id: productObjectId });
        
        if (saleItemCount > 0) {
          throw new ConflictException('Cannot delete product: Product is referenced in sale records. Please remove sale records first.');
        }
      }

      return this.productModel.findByIdAndDelete(id).exec();
    } catch (error) {
      if (error instanceof ConflictException || error instanceof NotFoundException) {
        throw error;
      }
      throw new ConflictException('Cannot delete product. It may be used in other records.');
    }
  }

  // Soft delete with history preservation
  async softDelete(id: string) {
    const product = await this.findOne(id);
    
    // Update the product to indicate it's archived/deleted
    await this.productModel.findByIdAndUpdate(id, {
      reference_code: `ARCHIVED_${product.reference_code}_${Date.now()}`,
      name: `[ARCHIVED] ${product.name}`,
      deletedAt: new Date(),
    }).exec();

    return this.findOne(id);
  }

  // Restore soft-deleted product
  async restore(id: string) {
    const product = await this.productModel.findById(id).exec();

    if (!product) {
      throw new NotFoundException('Product not found');
    }

    // Remove the archived prefix from name
    const name = product.name.replace('[ARCHIVED] ', '');
    // Remove the archived prefix and timestamp from reference code
    const reference_code = product.reference_code.replace(/ARCHIVED_(.+)_\d+/, '$1');

    return this.productModel.findByIdAndUpdate(
      id,
      {
        name,
        reference_code,
        deletedAt: null,
      },
      { new: true }
    ).exec();
  }
}

