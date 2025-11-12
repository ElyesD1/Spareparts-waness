export class CreateCustomerDto {
  readonly name: string;
  readonly email?: string | null;
  readonly phone_number: string;
  readonly address?: string;
  readonly company_name?: string;
  readonly tax_number?: string;
  readonly cin?: number | null;
  readonly credit_limit?: number;
  readonly is_credit_authorized?: boolean;
} 

