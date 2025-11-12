-- Fix corrupted users table
-- Run this in your MySQL client or phpMyAdmin

-- Step 1: Drop the corrupted table
DROP TABLE IF EXISTS users;

-- Step 2: Create new users table
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  phone_number VARCHAR(20) UNIQUE NOT NULL,
  role ENUM('admin', 'manager', 'cashier') DEFAULT 'cashier',
  warehouse_id INT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  deleted_at TIMESTAMP NULL,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Step 3: Create default admin user
INSERT INTO users (name, email, password_hash, phone_number, role, warehouse_id, is_active)
VALUES ('Admin User', 'admin@example.com', '$2b$10$default.hash.here', '1234567890', 'admin', 1, true);

-- Step 4: Verify
SELECT COUNT(*) as user_count FROM users; 