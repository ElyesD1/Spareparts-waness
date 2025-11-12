const mysql = require('mysql2/promise');

async function fixTablespace() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'spare_parts_management1'
  });

  try {
    console.log('🔧 Fixing tablespace issue...\n');

    // Step 1: Drop table if exists (this should clean up tablespace)
    console.log('🗑️ Step 1: Dropping table if exists...');
    try {
      await connection.execute('DROP TABLE IF EXISTS users');
      console.log('✅ Table dropped successfully');
    } catch (error) {
      console.log('⚠️ Drop failed:', error.message);
    }

    // Step 2: Check if table still exists
    console.log('\n🔍 Step 2: Checking if table still exists...');
    const [tables] = await connection.execute('SHOW TABLES LIKE "users"');
    console.log(`Table exists: ${tables.length > 0 ? 'YES' : 'NO'}`);

    if (tables.length > 0) {
      console.log('⚠️ Table still exists, trying force drop...');
      try {
        await connection.execute('DROP TABLE users FORCE');
        console.log('✅ Force drop successful');
      } catch (error) {
        console.log('⚠️ Force drop failed:', error.message);
      }
    }

    // Step 3: Create new table
    console.log('\n🏗️ Step 3: Creating new table...');
    const createSQL = `
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
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    `;
    
    await connection.execute(createSQL);
    console.log('✅ New table created successfully');

    // Step 4: Create default user
    console.log('\n👤 Step 4: Creating default admin user...');
    const insertSQL = `
      INSERT INTO users (name, email, password_hash, phone_number, role, warehouse_id, is_active)
      VALUES ('Admin User', 'admin@example.com', '$2b$10$default.hash.here', '1234567890', 'admin', 1, true)
    `;
    
    await connection.execute(insertSQL);
    console.log('✅ Default admin user created');

    // Step 5: Verify
    console.log('\n✅ Step 5: Verifying...');
    const [result] = await connection.execute('SELECT COUNT(*) as count FROM users');
    console.log(`✅ Success: ${result[0].count} users in table`);

    console.log('\n🎉 Tablespace issue fixed!');

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('❌ Error Code:', error.code);
    
    if (error.code === 'ER_TABLESPACE_EXISTS') {
      console.log('\n💡 Try this manual fix:');
      console.log('1. Stop MySQL service');
      console.log('2. Delete the users table files from MySQL data directory');
      console.log('3. Restart MySQL service');
      console.log('4. Run this script again');
    }
  } finally {
    await connection.end();
  }
}

fixTablespace(); 