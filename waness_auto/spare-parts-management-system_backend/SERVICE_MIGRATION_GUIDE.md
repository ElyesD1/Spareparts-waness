# MongoDB Migration Service Update Guide

## Overview
All entities and modules have been successfully converted to Mongoose. Now all services need to be updated to use Mongoose Model instead of TypeORM Repository.

## Key Changes Required in Services

### 1. Import Changes

**OLD (TypeORM):**
```typescript
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
```

**NEW (Mongoose):**
```typescript
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
```

### 2. Constructor Injection Changes

**OLD (TypeORM):**
```typescript
constructor(
  @InjectRepository(User)
  private userRepository: Repository<User>,
) {}
```

**NEW (Mongoose):**
```typescript
constructor(
  @InjectModel(User.name)
  private userModel: Model<UserDocument>,
) {}
```

### 3. Common Method Mappings

#### Find All
**OLD:** `this.userRepository.find()`
**NEW:** `this.userModel.find().exec()`

#### Find One by ID
**OLD:** `this.userRepository.findOne({ where: { id } })`
**NEW:** `this.userModel.findById(id).exec()`

#### Find One with Conditions
**OLD:** `this.userRepository.findOne({ where: { email } })`
**NEW:** `this.userModel.findOne({ email }).exec()`

#### Create
**OLD:** 
```typescript
const user = this.userRepository.create(createUserDto);
return this.userRepository.save(user);
```
**NEW:**
```typescript
const user = new this.userModel(createUserDto);
return user.save();
```

#### Update
**OLD:** `this.userRepository.update(id, updateUserDto)`
**NEW:** `this.userModel.findByIdAndUpdate(id, updateUserDto, { new: true }).exec()`

#### Delete
**OLD:** `this.userRepository.delete(id)`
**NEW:** `this.userModel.findByIdAndDelete(id).exec()`

#### Save
**OLD:** `this.userRepository.save(entity)`
**NEW:** `entity.save()` or `this.userModel.create(entity)`

### 4. Query Builder Replacements

**OLD (TypeORM QueryBuilder):**
```typescript
this.userRepository.createQueryBuilder('user')
  .leftJoinAndSelect('user.warehouse', 'warehouse')
  .where('user.email = :email', { email })
  .getOne();
```

**NEW (Mongoose populate):**
```typescript
this.userModel
  .findOne({ email })
  .populate('warehouse_id')
  .exec();
```

### 5. Relations (populate)

**OLD:** Relations are automatically loaded with `eager: true` or `relations: ['warehouse']`
**NEW:** Use `.populate('fieldName')` for each relation you need

Example:
```typescript
this.productModel
  .find()
  .populate('supplier_id')
  .exec();
```

### 6. ID References

**Important:** MongoDB uses `_id` as ObjectId, not numeric IDs.

- When saving references, save the `_id` field
- When populating, Mongoose automatically resolves ObjectId references
- Convert string IDs to ObjectId when needed: `new Types.ObjectId(idString)`

## Next Steps

Update all service files in this order:
1. users.service.ts
2. warehouses/warehouse.service.ts
3. suppliers/suppliers.service.ts
4. products/products.service.ts
5. purchases/purchases.service.ts
6. purchase-item/purchase-item.service.ts
7. sales/sales.service.ts
8. sale-item/sale-item.service.ts
9. product-stocks/product-stocks.service.ts
10. stock-movement/stock-movement.service.ts
11. customers/customers.service.ts
12. credit-sales/credit-sales.service.ts
13. credit-payments/credit-payments.service.ts
14. supplier-credits/supplier-credits.service.ts
15. purchase-returns/purchase-returns.service.ts
16. product-transfers/product-transfers.service.ts
17. operational_expenses/operational-expenses.service.ts
18. otp/otp.service.ts
19. auth/auth.service.ts
20. auth/jwt.strategy.ts

Each service file needs systematic updates following the patterns above.
