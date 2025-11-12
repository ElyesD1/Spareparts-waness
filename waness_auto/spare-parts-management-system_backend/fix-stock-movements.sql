-- Fix Stock Movements table structure
-- Add missing columns to match the entity

USE spare_parts_management1;

-- Add missing columns if they don't exist
ALTER TABLE stock_movements 
ADD COLUMN IF NOT EXISTS source_type VARCHAR(255) NULL,
ADD COLUMN IF NOT EXISTS source_id INT NULL;

-- Verify the table structure
DESCRIBE stock_movements;

-- Check for any existing data issues
SELECT 
    id,
    product_id,
    from_warehouse_id,
    to_warehouse_id,
    user_id,
    quantity,
    movement_type,
    source_type,
    source_id,
    created_at
FROM stock_movements 
LIMIT 10;







