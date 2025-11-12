import { MongooseModule } from "@nestjs/mongoose";
import { OperationalExpense, OperationalExpenseSchema } from "./operational-expense.entity";
import { Module } from "@nestjs/common";
import { OperationalExpensesController } from "./operational-expenses.controller";
import { OperationalExpensesService } from "./operational-expenses.service";

@Module({
    imports: [MongooseModule.forFeature([{ name: OperationalExpense.name, schema: OperationalExpenseSchema }])],
    controllers: [OperationalExpensesController],
    providers: [OperationalExpensesService],
    exports: [MongooseModule],
  })
  export class OperationalExpensesModule {}
  