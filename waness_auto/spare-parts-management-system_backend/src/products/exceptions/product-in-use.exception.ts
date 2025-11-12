import { ConflictException } from '@nestjs/common';

export class ProductInUseException extends ConflictException {
  constructor(productId: number, details: string) {
    super(`Product with ID ${productId} cannot be deleted: ${details}`);
  }
}