export class CreateCreditPaymentDto {
  credit_sale_id: number;
  received_by?: number; // Optional since we set it automatically
  amount: number;
  payment_date: string;
  payment_method: 'cash' | 'check' | 'bank_transfer';
  reference_number?: string;
  notes?: string;
  
  // Allow additional properties
  [key: string]: any;
} 

