-- ============================================================================
-- COMPLETE DATABASE RESET SCRIPT
-- WARNING: This will DELETE ALL DATA from your database!
-- ============================================================================

-- Disable foreign key checks to allow deleting data with relationships
SET FOREIGN_KEY_CHECKS = 0;

-- Delete from child tables first (deepest level)
DELETE FROM `sale_items`;
DELETE FROM `purchase_items`;
DELETE FROM `credit_sale_items`;
DELETE FROM `purchase_return_items`;
DELETE FROM `stock_movements`;
DELETE FROM `product_stocks`;
DELETE FROM `product_transfers`;

-- Delete from middle level tables
DELETE FROM `sales`;
DELETE FROM `purchases`;
DELETE FROM `credit_sales`;
DELETE FROM `credit_payments`;
DELETE FROM `purchase_returns`;
DELETE FROM `supplier_credits`;
DELETE FROM `operational_expenses`;

-- Delete from base tables
DELETE FROM `products`;
DELETE FROM `customers`;
DELETE FROM `suppliers`;

-- Delete from tables that are referenced by users (like warehouses)
-- This needs to be done before we can delete other dependent data
DELETE FROM `users` WHERE `id` > 0;
DELETE FROM `warehouses`;

-- Reset auto increment values
ALTER TABLE `products` AUTO_INCREMENT = 1;
ALTER TABLE `suppliers` AUTO_INCREMENT = 1;
ALTER TABLE `warehouses` AUTO_INCREMENT = 1;
ALTER TABLE `customers` AUTO_INCREMENT = 1;
ALTER TABLE `sales` AUTO_INCREMENT = 1;
ALTER TABLE `purchases` AUTO_INCREMENT = 1;
ALTER TABLE `credit_sales` AUTO_INCREMENT = 1;
ALTER TABLE `supplier_credits` AUTO_INCREMENT = 1;
ALTER TABLE `users` AUTO_INCREMENT = 1;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;

-- Optimize all tables
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
