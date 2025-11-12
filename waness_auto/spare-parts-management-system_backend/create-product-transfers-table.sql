-- Create product_transfers table
CREATE TABLE IF NOT EXISTS product_transfers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    from_warehouse_id INT NOT NULL,
    to_warehouse_id INT NOT NULL,
    quantity INT NOT NULL,
    priority ENUM('low', 'normal', 'high', 'urgent') DEFAULT 'normal',
    status ENUM('pending', 'approved', 'rejected', 'in_transit', 'completed', 'cancelled') DEFAULT 'pending',
    reason TEXT NOT NULL,
    notes TEXT NULL,
    
    -- User tracking
    requested_by INT NOT NULL,
    approved_by INT NULL,
    processed_by INT NULL,
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    approved_at TIMESTAMP NULL,
    processed_at TIMESTAMP NULL,
    
    -- Foreign keys
    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (from_warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (to_warehouse_id) REFERENCES warehouses(id),
    FOREIGN KEY (requested_by) REFERENCES users(id),
    FOREIGN KEY (approved_by) REFERENCES users(id),
    FOREIGN KEY (processed_by) REFERENCES users(id),
    
    -- Indexes for performance
    INDEX idx_product_transfers_product (product_id),
    INDEX idx_product_transfers_from_warehouse (from_warehouse_id),
    INDEX idx_product_transfers_to_warehouse (to_warehouse_id),
    INDEX idx_product_transfers_status (status),
    INDEX idx_product_transfers_priority (priority),
    INDEX idx_product_transfers_requested_by (requested_by),
    INDEX idx_product_transfers_created_at (created_at)
);
