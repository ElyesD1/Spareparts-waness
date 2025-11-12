USE spare_parts_management1;

-- First, let's check the current enum values
SELECT DISTINCT movement_type FROM stock_movements;

-- Update existing records to use new enum values
UPDATE stock_movements 
SET movement_type = 'vente' 
WHERE movement_type = 'sale';

UPDATE stock_movements 
SET movement_type = 'achat' 
WHERE movement_type = 'purchase';

UPDATE stock_movements 
SET movement_type = 'retour' 
WHERE movement_type = 'adjustment';

-- Check if we have any other values that need updating
SELECT DISTINCT movement_type FROM stock_movements;

-- Drop the old enum and create new one
ALTER TABLE stock_movements 
MODIFY COLUMN movement_type ENUM('vente', 'achat', 'retour') NOT NULL;

-- Verify the change
DESCRIBE stock_movements;
SELECT DISTINCT movement_type FROM stock_movements;
