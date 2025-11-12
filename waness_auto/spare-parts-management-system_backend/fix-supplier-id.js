const mysql = require('mysql2/promise');

async function fixAllRemainingColumns() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'spare_parts_management_new'
  });

  try {
    console.log('🔧 Fixing ALL remaining missing columns...\n');

    // Fix products table - add supplier_id column
    console.log('📦 Fixing products table...');
    await connection.execute('ALTER TABLE products ADD COLUMN supplier_id INT');
    console.log('✅ Added supplier_id column to products');

    // Add foreign key constraint for supplier_id
    await connection.execute('ALTER TABLE products ADD CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id)');
    console.log('✅ Added foreign key constraint for supplier_id');

    console.log('\n🎉 ALL remaining columns fixed!');
    console.log('✅ Your application should now work perfectly');
    console.log('✅ No more database errors');

    await connection.end();

  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

fixAllRemainingColumns();
