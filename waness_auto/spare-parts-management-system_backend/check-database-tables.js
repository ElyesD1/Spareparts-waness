const mysql = require('mysql2/promise');

async function checkDatabaseTables() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'spare_parts_management1'
  });

  try {
    console.log('🔍 Checking database tables...\n');

    // Check if database exists
    const [databases] = await connection.execute('SHOW DATABASES');
    const dbExists = databases.some(db => db.Database === 'spare_parts_management1');
    console.log(`Database 'spare_parts_management1' exists: ${dbExists ? '✅ YES' : '❌ NO'}`);

    if (!dbExists) {
      console.log('❌ Database does not exist!');
      return;
    }

    // Show all tables
    const [tables] = await connection.execute('SHOW TABLES');
    console.log('\n📋 Existing tables:');
    tables.forEach(table => {
      const tableName = Object.values(table)[0];
      console.log(`  - ${tableName}`);
    });

    // Check if users table exists
    const usersTableExists = tables.some(table => {
      const tableName = Object.values(table)[0];
      return tableName === 'users';
    });

    console.log(`\n👥 Users table exists: ${usersTableExists ? '✅ YES' : '❌ NO'}`);

    if (!usersTableExists) {
      console.log('\n🚨 CRITICAL: Users table is missing!');
      console.log('This will break authentication and user management.');
    }

    // Check table structure if it exists
    if (usersTableExists) {
      console.log('\n🔍 Users table structure:');
      const [columns] = await connection.execute('DESCRIBE users');
      columns.forEach(col => {
        console.log(`  - ${col.Field}: ${col.Type} ${col.Null === 'NO' ? 'NOT NULL' : 'NULL'} ${col.Key ? `(${col.Key})` : ''}`);
      });
    }

  } catch (error) {
    console.error('❌ Database connection error:', error.message);
  } finally {
    await connection.end();
  }
}

checkDatabaseTables(); 