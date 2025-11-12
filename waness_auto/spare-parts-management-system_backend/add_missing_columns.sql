-- Add missing columns to database tables
-- Run this script to add the columns that exist in TypeORM entities but not in the database

-- 1. Add missing columns to sales table
ALTER TABLE `sales` 
ADD COLUMN `source_credit_sale_id` int NULL,
ADD UNIQUE KEY `UK_sales_source_credit_sale_id` (`source_credit_sale_id`);

-- 2. Add missing columns to products table
ALTER TABLE `products` 
ADD COLUMN `supplier_id` int NULL,
ADD COLUMN `supplier_price` decimal(10,2) NULL,
ADD CONSTRAINT `FK_products_supplier` 
FOREIGN KEY (`supplier_id`) REFERENCES `suppliers`(`id`);

-- 3. Add missing columns to purchases table
ALTER TABLE `purchases` 
ADD COLUMN `status` varchar(255) DEFAULT 'pending',
ADD COLUMN `delivered_by` int NULL,
ADD COLUMN `deliveredAt` timestamp NULL,
ADD CONSTRAINT `FK_purchases_delivered_by` 
FOREIGN KEY (`delivered_by`) REFERENCES `users`(`id`);

-- 4. Add missing columns to credit_sales table
ALTER TABLE `credit_sales` 
ADD COLUMN `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- 5. Add missing columns to customers table
ALTER TABLE `customers` 
ADD COLUMN `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

-- 6. Add missing columns to credit_payments table
ALTER TABLE `credit_payments` 
ADD COLUMN `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- 7. Add missing columns to otp table
ALTER TABLE `otp` 
ADD COLUMN `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Note: Make sure to run this script on your database
-- You may need to adjust the table names if they're different in your database


