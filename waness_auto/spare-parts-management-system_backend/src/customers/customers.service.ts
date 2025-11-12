import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Customer, CustomerDocument } from './customer.entity';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { UpdateCustomerDto } from './dto/update-customer.dto';

@Injectable()
export class CustomersService {
  constructor(
    @InjectModel(Customer.name)
    private customerModel: Model<CustomerDocument>,
  ) {}

  async create(createCustomerDto: CreateCustomerDto): Promise<Customer> {
    // Normalize empty email to null to satisfy nullable unique constraint
    const dto: any = { ...createCustomerDto };
    if (dto.email === '') dto.email = null;
    
    // Validate CIN if provided: must be 8-digit integer
    if (dto.cin !== undefined && dto.cin !== null) {
      const cinNum = Number(dto.cin);
      if (!Number.isInteger(cinNum) || cinNum < 0 || cinNum.toString().length !== 8) {
        throw new Error('CIN must be an 8-digit integer');
      }
      dto.cin = cinNum;
    }
    
    const customer = new this.customerModel(dto);
    return customer.save();
  }

  async findAll(): Promise<Customer[]> {
    return this.customerModel.find({ is_active: true })
      .sort({ name: 1 })
      .exec();
  }

  async findOne(id: string): Promise<Customer> {
    const customer = await this.customerModel.findOne({ _id: id, is_active: true }).exec();
    if (!customer) {
      throw new NotFoundException(`Customer with ID ${id} not found`);
    }
    return customer;
  }

  async update(id: string, updateCustomerDto: UpdateCustomerDto): Promise<Customer> {
    await this.findOne(id); // Validate exists
    const dto: any = { ...updateCustomerDto };
    if (dto.email === '') dto.email = null;
    
    // Validate CIN if provided: must be 8-digit integer
    if (dto.cin !== undefined && dto.cin !== null) {
      const cinNum = Number(dto.cin);
      if (!Number.isInteger(cinNum) || cinNum < 0 || cinNum.toString().length !== 8) {
        throw new Error('CIN must be an 8-digit integer');
      }
      dto.cin = cinNum;
    }
    
    const updated = await this.customerModel.findByIdAndUpdate(id, dto, { new: true }).exec();
    if (!updated) throw new NotFoundException(`Customer with ID ${id} not found`);
    return updated;
  }

  async remove(id: string): Promise<void> {
    await this.findOne(id); // Validate exists
    await this.customerModel.findByIdAndUpdate(id, { is_active: false }, { new: true }).exec();
  }

  async updateBalance(id: string, amount: number): Promise<void> {
    const customer = await this.findOne(id);
    const newBalance = customer.current_balance + amount;
    await this.customerModel.findByIdAndUpdate(id, { current_balance: newBalance }, { new: true }).exec();
  }
}

