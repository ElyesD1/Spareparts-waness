import { Body, Controller, Delete, Get, Param, ParseIntPipe, Post, Put } from "@nestjs/common";
import { OperationalExpensesService } from "./operational-expenses.service";
import { CreateOperationalExpenseDto } from "./dto/create-operational-expense.dto";
import { UpdateOperationalExpenseDto } from "./dto/update-operational-expense.dto";

@Controller('operational-expenses')
export class OperationalExpensesController {
  constructor(private svc: OperationalExpensesService) {}

  @Post() create(@Body() dto: CreateOperationalExpenseDto) {
    return this.svc.create(dto);
  }

  @Get() findAll() {
    return this.svc.findAll();
  }

  @Get(':id') findOne(@Param('id') id: string) {
    return this.svc.findOne(id);
  }

  @Put(':id') update(@Param('id') id: string, @Body() dto: UpdateOperationalExpenseDto) {
    return this.svc.update(id, dto);
  }

  @Delete(':id') remove(@Param('id') id: string) {
    return this.svc.remove(id);
  }
}

