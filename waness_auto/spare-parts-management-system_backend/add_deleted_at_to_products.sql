-- Add deletedAt column to products table for soft deletes
-- This column is required by the Product entity which uses @DeleteDateColumn()

ALTER TABLE `products` 
ADD COLUMN `deletedAt` datetime(6) NULL;

-- Create index on deletedAt column for better query performance
CREATE INDEX `IDX_products_deletedAt` ON `products` (`deletedAt`);