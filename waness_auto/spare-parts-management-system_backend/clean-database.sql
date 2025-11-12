-- ============================================================================
-- DATABASE CLEANING SCRIPT FOR spare_parts_management1
-- ============================================================================
-- This script provides various cleaning operations for your database
-- Run the sections you need based on your requirements
-- ============================================================================

-- ============================================================================
-- SECTION 1: SOFT DELETE CLEANUP
-- Remove soft-deleted records (where deletedAt is NOT NULL)
-- ============================================================================

-- Clean soft-deleted products
DELETE FROM `products` WHERE `deletedAt` IS NOT NULL;

-- ============================================================================
-- SECTION 2: ORPHANED RECORDS CLEANUP
-- Remove records that reference non-existent parent records
-- ============================================================================

-- Clean product_stocks that reference deleted products
DELETE FROM `product_stocks` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- Clean sale_items that reference deleted products
DELETE FROM `sale_items` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- Clean purchase_items that reference deleted products
DELETE FROM `purchase_items` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- Clean credit_sale_items that reference deleted products
DELETE FROM `credit_sale_items` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- Clean stock_movements that reference deleted products
DELETE FROM `stock_movements` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- Clean products that reference deleted suppliers
UPDATE `products` 
SET `supplier_id` = NULL 
WHERE `supplier_id` IS NOT NULL 
AND `supplier_id` NOT IN (SELECT `id` FROM `suppliers`);

-- ============================================================================
-- SECTION 3: DUPLICATE RECORDS CLEANUP
-- ============================================================================

-- Find and remove duplicate products by reference_code (keeping the oldest one)
DELETE p1 FROM `products` p1
INNER JOIN `products` p2 
WHERE p1.`id` > p2.`id` 
AND p1.`reference_code` = p2.`reference_code`;

-- ============================================================================
-- SECTION 4: NULL/EMPTY DATA CLEANUP
-- ============================================================================

-- Remove products with NULL or empty names
DELETE FROM `products` 
WHERE `name` IS NULL OR `name` = '' OR TRIM(`name`) = '';

-- Remove products with NULL or empty reference codes
DELETE FROM `products` 
WHERE `reference_code` IS NULL OR `reference_code` = '' OR TRIM(`reference_code`) = '';

-- ============================================================================
-- SECTION 5: INVALID DATA CLEANUP
-- ============================================================================

-- Remove products with negative or zero prices
DELETE FROM `products` 
WHERE `unit_price` <= 0;

-- Remove stock movements with invalid quantities
DELETE FROM `stock_movements` 
WHERE `quantity` = 0 OR `quantity` IS NULL;

-- ============================================================================
-- SECTION 6: OLD DATA CLEANUP (OPTIONAL)
-- Remove data older than a specific date
-- ============================================================================

-- Remove sales older than 2 years (UNCOMMENT IF NEEDED)
-- DELETE FROM `sales` 
-- WHERE `createdAt` < DATE_SUB(NOW(), INTERVAL 2 YEAR);

-- Remove purchases older than 2 years (UNCOMMENT IF NEEDED)
-- DELETE FROM `purchases` 
-- WHERE `createdAt` < DATE_SUB(NOW(), INTERVAL 2 YEAR);

-- ============================================================================
-- SECTION 7: RESET AUTO INCREMENT VALUES
-- ============================================================================

-- Reset auto increment to next available ID for each table
ALTER TABLE `products` AUTO_INCREMENT = 1;
ALTER TABLE `suppliers` AUTO_INCREMENT = 1;
ALTER TABLE `warehouses` AUTO_INCREMENT = 1;
ALTER TABLE `users` AUTO_INCREMENT = 1;
ALTER TABLE `sales` AUTO_INCREMENT = 1;
ALTER TABLE `purchases` AUTO_INCREMENT = 1;
ALTER TABLE `customers` AUTO_INCREMENT = 1;

-- ============================================================================
-- SECTION 8: TRUNCATE TABLES (COMPLETE DATA REMOVAL - USE WITH CAUTION!)
-- ============================================================================
-- WARNING: These commands will DELETE ALL DATA from the tables
-- Only uncomment and use if you want to completely reset specific tables

-- TRUNCATE TABLE `sale_items`;
-- TRUNCATE TABLE `sales`;
-- TRUNCATE TABLE `purchase_items`;
-- TRUNCATE TABLE `purchases`;
-- TRUNCATE TABLE `credit_sale_items`;
-- TRUNCATE TABLE `credit_sales`;
-- TRUNCATE TABLE `credit_payments`;
-- TRUNCATE TABLE `stock_movements`;
-- TRUNCATE TABLE `product_stocks`;
-- TRUNCATE TABLE `product_transfers`;
-- TRUNCATE TABLE `purchase_returns`;
-- TRUNCATE TABLE `purchase_return_items`;
-- TRUNCATE TABLE `supplier_credits`;
-- TRUNCATE TABLE `supplier_credit_usages`;
-- TRUNCATE TABLE `operational_expenses`;
-- TRUNCATE TABLE `products`;
-- TRUNCATE TABLE `customers`;
-- TRUNCATE TABLE `suppliers`;
-- TRUNCATE TABLE `warehouses`;

-- ============================================================================
-- SECTION 9: VACUUM/OPTIMIZE TABLES
-- ============================================================================

-- Optimize tables to reclaim space and improve performance
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

-- ============================================================================
-- SECTION 10: VERIFICATION QUERIES
-- Run these to check the state of your database after cleaning
-- ============================================================================

-- Check table sizes
SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) AS 'Size (MB)'
FROM 
    information_schema.TABLES
WHERE 
    TABLE_SCHEMA = 'spare_parts_management1'
ORDER BY 
    (DATA_LENGTH + INDEX_LENGTH) DESC;

-- Check for soft-deleted products
SELECT COUNT(*) AS soft_deleted_products 
FROM `products` 
WHERE `deletedAt` IS NOT NULL;

-- Check for orphaned records
SELECT 
    'product_stocks' AS table_name,
    COUNT(*) AS orphaned_records
FROM `product_stocks` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`)
UNION ALL
SELECT 
    'sale_items',
    COUNT(*)
FROM `sale_items` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`)
UNION ALL
SELECT 
    'purchase_items',
    COUNT(*)
FROM `purchase_items` 
WHERE `product_id` NOT IN (SELECT `id` FROM `products`);

-- ============================================================================
-- END OF CLEANING SCRIPT
-- ============================================================================
