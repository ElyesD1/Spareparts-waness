USE spare_parts_management1;

-- First, let's see what duplicates we have
SELECT 
    source_type,
    source_id,
    product_id,
    movement_type,
    user_id,
    quantity,
    COUNT(*) as duplicate_count,
    GROUP_CONCAT(id ORDER BY id) as duplicate_ids
FROM stock_movements 
GROUP BY source_type, source_id, product_id, movement_type, user_id, quantity, DATE(created_at)
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Show the actual duplicate records
SELECT 
    id,
    source_type,
    source_id,
    product_id,
    movement_type,
    user_id,
    quantity,
    created_at,
    note
FROM stock_movements 
WHERE (source_type, source_id, product_id, movement_type, user_id, quantity) IN (
    SELECT 
        source_type,
        source_id,
        product_id,
        movement_type,
        user_id,
        quantity
    FROM stock_movements 
    GROUP BY source_type, source_id, product_id, movement_type, user_id, quantity, DATE(created_at)
    HAVING COUNT(*) > 1
)
ORDER BY source_type, source_id, product_id, movement_type, user_id, quantity, created_at;

-- Delete duplicates, keeping only the first one (lowest ID)
DELETE sm1 FROM stock_movements sm1
INNER JOIN stock_movements sm2 
WHERE sm1.id > sm2.id 
AND sm1.source_type = sm2.source_type
AND sm1.source_id = sm2.source_id
AND sm1.product_id = sm2.product_id
AND sm1.movement_type = sm2.movement_type
AND sm1.user_id = sm2.user_id
AND sm1.quantity = sm2.quantity
AND DATE(sm1.created_at) = DATE(sm2.created_at);

-- Verify duplicates are gone
SELECT 
    source_type,
    source_id,
    product_id,
    movement_type,
    user_id,
    quantity,
    COUNT(*) as count
FROM stock_movements 
GROUP BY source_type, source_id, product_id, movement_type, user_id, quantity, DATE(created_at)
HAVING COUNT(*) > 1;

-- Show final count
SELECT COUNT(*) as total_movements FROM stock_movements;






