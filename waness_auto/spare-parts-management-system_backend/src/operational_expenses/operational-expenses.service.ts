import { Injectable } from "@nestjs/common";
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { UpdateOperationalExpenseDto } from "./dto/update-operational-expense.dto";
import { OperationalExpense, OperationalExpenseDocument } from "./operational-expense.entity";
import { CreateOperationalExpenseDto } from "./dto/create-operational-expense.dto";

@Injectable()
export class OperationalExpensesService {
  constructor(
    @InjectModel(OperationalExpense.name) 
    private model: Model<OperationalExpenseDocument>
  ) {}

  async create(dto: CreateOperationalExpenseDto) {
    const created = new this.model(dto);
    return created.save();
  }

  async findAll() {
    return this.model.find()
      .populate('warehouse_id')
      .populate('created_by')
      .exec();
  }

  async findOne(id: string) {
    return this.model.findById(id)
      .populate('warehouse_id')
      .populate('created_by')
      .exec();
  }

  async update(id: string, dto: UpdateOperationalExpenseDto) {
    await this.model.findByIdAndUpdate(id, dto, { new: true }).exec();
    return this.findOne(id);
  }

  async remove(id: string) {
    return this.model.findByIdAndDelete(id).exec();
  }
}

