const mysql = require('mysql2/promise');

async function createTempUsersTable() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'spare_parts_management1'
  });

  try {
    console.log('🏗️ Creating temporary users table...\n');

    // Create table with different name
    const createSQL = `
      CREATE TABLE users_new (
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
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `;
    
    await connection.execute(createSQL);
    console.log('✅ Temporary users table created successfully');

    // Create default admin user
    const insertSQL = `
      INSERT INTO users_new (name, email, password_hash, phone_number, role, warehouse_id, is_active)
      VALUES ('Admin User', 'admin@example.com', '$2b$10$default.hash.here', '1234567890', 'admin', 1, true)
    `;
    
    await connection.execute(insertSQL);
    console.log('✅ Default admin user created');

    // Test query
    const [result] = await connection.execute('SELECT COUNT(*) as count FROM users_new');
    console.log(`✅ Test successful: ${result[0].count} users found`);

    console.log('\n🎉 Temporary users table is ready!');
    console.log('\n💡 Next steps:');
    console.log('1. Update your entity to use "users_new" table name');
    console.log('2. Or manually delete MySQL data files and recreate "users" table');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await connection.end();
  }
}

createTempUsersTable(); 