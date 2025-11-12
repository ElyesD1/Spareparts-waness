export class CreatePurchaseItemDto {
  // Add purchase item properties here
  readonly purchase_id: string;
  readonly product_id: string;
  readonly warehouse_id: string;
  readonly quantity: number;
  readonly unit_price: number;
} 

