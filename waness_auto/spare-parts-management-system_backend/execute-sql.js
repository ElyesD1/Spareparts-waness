const mysql = require('mysql2/promise');
const fs = require('fs');

async function executeSQL() {
  const connection = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'spare_parts_management1'
  });

  try {
    console.log('🔧 Executing SQL to fix users table...\n');

    // Read SQL file
    const sql = fs.readFileSync('fix-users-direct.sql', 'utf8');
    const commands = sql.split(';').filter(cmd => cmd.trim());

    for (let i = 0; i < commands.length; i++) {
      const command = commands[i].trim();
      if (command && !command.startsWith('--')) {
        console.log(`Executing: ${command.substring(0, 50)}...`);
        try {
          const [result] = await connection.execute(command);
          if (result.affectedRows !== undefined) {
            console.log(`✅ Affected rows: ${result.affectedRows}`);
          }
        } catch (error) {
          console.log(`⚠️ Command ${i + 1} failed: ${error.message}`);
        }
      }
    }

    console.log('\n✅ SQL execution completed');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    await connection.end();
  }
}

executeSQL(); 