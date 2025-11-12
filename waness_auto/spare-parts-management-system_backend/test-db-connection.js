const mysql = require('mysql2/promise');

async function testDatabaseConnection() {
  try {
    // Create connection
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '',
      database: 'spare_parts_management1'
    });

    console.log('✅ Database connection successful');

    // Check if customers table exists
    const [tables] = await connection.execute('SHOW TABLES LIKE "customers"');
    if (tables.length === 0) {
      console.log('❌ Customers table does not exist');
      return;
    }

    console.log('✅ Customers table exists');

    // Check table structure
    const [columns] = await connection.execute('DESCRIBE customers');
    console.log('📋 Customers table structure:');
    columns.forEach(col => {
      console.log(`  ${col.Field}: ${col.Type} ${col.Null === 'YES' ? 'NULL' : 'NOT NULL'} ${col.Default ? `DEFAULT ${col.Default}` : ''}`);
    });

    // Check if table has any data
    const [rows] = await connection.execute('SELECT COUNT(*) as count FROM customers');
    console.log(`📊 Customers table has ${rows[0].count} records`);

    await connection.end();
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
  }
}

testDatabaseConnection();





