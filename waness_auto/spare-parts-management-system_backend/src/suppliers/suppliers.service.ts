import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { CreateSupplierDto } from './dto/create-supplier.dto';
import { Supplier, SupplierDocument } from './supplier.entity';

@Injectable()
export class SuppliersService {
  constructor(
    @InjectModel(Supplier.name)
    private readonly supplierModel: Model<SupplierDocument>,
  ) {}

  async create(createSupplierDto: CreateSupplierDto): Promise<Supplier> {
    const supplier = new this.supplierModel(createSupplierDto);
    return supplier.save();
  }

  async findAll(): Promise<Supplier[]> {
    return this.supplierModel.find().exec();
  }

  async findOne(id: string): Promise<Supplier | null> {
    return this.supplierModel.findById(id).exec();
  }

  async update(id: string, updateSupplierDto: Partial<Supplier>): Promise<Supplier | null> {
    return this.supplierModel
      .findByIdAndUpdate(id, updateSupplierDto, { new: true })
      .exec();
  }

  async remove(id: string): Promise<{ deleted: boolean }> {
    const result = await this.supplierModel.findByIdAndDelete(id).exec();
    return { deleted: !!result };
  }
}

