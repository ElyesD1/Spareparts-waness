export class CreatePurchaseDto {
  readonly supplier_id: string;
  readonly date: string; // or Date if you prefer
  readonly total_amount: number;
  readonly created_by: number;
  readonly status?: string; // optional, defaults to 'pending'
  readonly delivered_by?: number; // optional
  readonly deliveredAt?: string; // optional ISO string
  readonly final_amount?: number; // optional, amount after applying credits
} 

