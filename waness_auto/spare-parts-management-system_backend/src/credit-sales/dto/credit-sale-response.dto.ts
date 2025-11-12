import { CreditSale } from '../credit-sale.entity';

export class CreditSaleResponseDto extends CreditSale {
  total_paid: number;
  remaining_amount: number;
  is_completed: boolean;
}



