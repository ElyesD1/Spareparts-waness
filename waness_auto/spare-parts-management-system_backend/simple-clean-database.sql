-- ============================================================================
-- SIMPLE DATABASE CLEANING SCRIPT
-- This script will clean your database in one go
-- ============================================================================

-- Step 1: Clean soft-deleted products
DELETE FROM `products` WHERE `deletedAt` IS NOT NULL;

-- Step 2: Clean orphaned product_stocks
DELETE FROM `product_stocks` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- Step 3: Clean orphaned sale_items
DELETE FROM `sale_items` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- Step 4: Clean orphaned purchase_items
DELETE FROM `purchase_items` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- Step 5: Clean orphaned credit_sale_items
DELETE FROM `credit_sale_items` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- Step 6: Clean orphaned stock_movements
DELETE FROM `stock_movements` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- Step 7: Fix products with invalid supplier references
UPDATE `products` 
SET `supplier_id` = NULL 
WHERE `supplier_id` IS NOT NULL 
AND `supplier_id` NOT IN (SELECT `id` FROM `suppliers`);

-- Step 8: Remove duplicate products (keep the first one)
DELETE p1 FROM `products` p1
INNER JOIN `products` p2 
WHERE p1.`id` > p2.`id` 
AND p1.`reference_code` = p2.`reference_code`;

-- Step 9: Optimize all tables for better performance
OPTIMIZE TABLE `products`;
OPTIMIZE TABLE `suppliers`;
OPTIMIZE TABLE `warehouses`;
OPTIMIZE TABLE `users`;
OPTIMIZE TABLE `sales`;
OPTIMIZE TABLE `sale_items`;
OPTIMIZE TABLE `purchases`;
OPTIMIZE TABLE `purchase_items`;
OPTIMIZE TABLE `product_stocks`;
OPTIMIZE TABLE `stock_movements`;
OPTIMIZE TABLE `customers`;
OPTIMIZE TABLE `credit_sales`;
OPTIMIZE TABLE `credit_sale_items`;
OPTIMIZE TABLE `credit_payments`;
