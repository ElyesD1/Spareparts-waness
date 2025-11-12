-- Add barcode column to products table
ALTER TABLE products ADD COLUMN barcode VARCHAR(255) UNIQUE NULL;

-- Add index for better performance on barcode searches
CREATE INDEX idx_products_barcode ON products(barcode);

-- Add comment to the column
COMMENT ON COLUMN products.barcode IS 'Unique barcode identifier for the product';

