const mysql = require('mysql2/promise');

async function checkConstraints() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'spare_parts_management1'
  });

  try {
    console.log('🔍 Checking foreign key constraints...\n');

    // Check which tables reference users
    const [constraints] = await connection.execute(`
      SELECT 
        TABLE_NAME,
        COLUMN_NAME,
        CONSTRAINT_NAME,
        REFERENCED_TABLE_NAME,
        REFERENCED_COLUMN_NAME
      FROM information_schema.KEY_COLUMN_USAGE 
      WHERE REFERENCED_TABLE_NAME = 'users'
      AND TABLE_SCHEMA = 'spare_parts_management1'
    `);

    if (constraints.length > 0) {
      console.log('🔗 Tables that reference users:');
      constraints.forEach(constraint => {
        console.log(`  - ${constraint.TABLE_NAME}.${constraint.COLUMN_NAME} → users.${constraint.REFERENCED_COLUMN_NAME}`);
      });
      
      console.log('\n⚠️ Need to drop these constraints first:');
      constraints.forEach(constraint => {
        console.log(`  ALTER TABLE ${constraint.TABLE_NAME} DROP FOREIGN KEY ${constraint.CONSTRAINT_NAME};`);
      });
    } else {
      console.log('✅ No foreign key constraints found');
    }

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await connection.end();
  }
}

checkConstraints(); 