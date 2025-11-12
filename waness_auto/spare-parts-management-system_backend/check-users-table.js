const mysql = require('mysql2/promise');

async function checkUsersTable() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'spare_parts_management1'
  });

  try {
    console.log('🔍 Detailed Users Table Check...\n');

    // Check table engine
    const [tableInfo] = await connection.execute(`
      SELECT TABLE_NAME, ENGINE, TABLE_ROWS, DATA_LENGTH, INDEX_LENGTH 
      FROM information_schema.TABLES 
      WHERE TABLE_SCHEMA = 'spare_parts_management1' AND TABLE_NAME = 'users'
    `);
    
    if (tableInfo.length > 0) {
      console.log('📊 Table Info:');
      console.log(`  - Name: ${tableInfo[0].TABLE_NAME}`);
      console.log(`  - Engine: ${tableInfo[0].ENGINE}`);
      console.log(`  - Rows: ${tableInfo[0].TABLE_ROWS}`);
      console.log(`  - Data Size: ${tableInfo[0].DATA_LENGTH} bytes`);
    } else {
      console.log('❌ Table not found in information_schema');
    }

    // Check table structure
    console.log('\n🔍 Table Structure:');
    const [columns] = await connection.execute('DESCRIBE users');
    columns.forEach(col => {
      console.log(`  - ${col.Field}: ${col.Type} ${col.Null === 'NO' ? 'NOT NULL' : 'NULL'} ${col.Key ? `(${col.Key})` : ''} ${col.Default ? `DEFAULT ${col.Default}` : ''}`);
    });

    // Test simple query
    console.log('\n🧪 Testing simple query...');
    const [testResult] = await connection.execute('SELECT COUNT(*) as count FROM users');
    console.log(`✅ Query successful: ${testResult[0].count} users found`);

    // Test with LIMIT
    console.log('\n🧪 Testing with LIMIT...');
    const [users] = await connection.execute('SELECT id, name, email FROM users LIMIT 3');
    console.log('✅ Users found:', users.length);
    users.forEach(user => {
      console.log(`  - ID: ${user.id}, Name: ${user.name}, Email: ${user.email}`);
    });

  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('❌ Error Code:', error.code);
    console.error('❌ SQL State:', error.sqlState);
  } finally {
    await connection.end();
  }
}

checkUsersTable(); 