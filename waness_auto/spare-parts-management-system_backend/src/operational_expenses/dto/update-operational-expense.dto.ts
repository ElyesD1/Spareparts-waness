import { PartialType } from '@nestjs/mapped-types';
import { CreateOperationalExpenseDto } from './create-operational-expense.dto';
export class UpdateOperationalExpenseDto extends PartialType(CreateOperationalExpenseDto) {}


