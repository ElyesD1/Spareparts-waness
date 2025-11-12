const mysql = require('mysql2/promise');

async function fixWarehouseAssignment() {
  try {
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '',
      database: 'spare_parts_management1'
    });

    console.log('✅ Database connection successful');

    // Check current user warehouse assignments
    console.log('\n🔍 Current user warehouse assignments:');
    const [users] = await connection.execute(`
      SELECT id, name, email, warehouse_id FROM users ORDER BY id
    `);
    
    users.forEach(user => {
      const warehouseInfo = user.warehouse_id ? `Warehouse ID: ${user.warehouse_id}` : 'No warehouse assigned';
      console.log(`  User ID: ${user.id}, Name: ${user.name}, Email: ${user.email} - ${warehouseInfo}`);
    });

    // Find users without warehouse assignment
    const usersWithoutWarehouse = users.filter(user => !user.warehouse_id);
    
    if (usersWithoutWarehouse.length === 0) {
      console.log('\nℹ️ All users already have warehouse assignments');
    } else {
      console.log(`\n🔧 Found ${usersWithoutWarehouse.length} users without warehouse assignment`);
      
      // Assign the first user without warehouse to warehouse ID 1
      const userToAssign = usersWithoutWarehouse[0];
      console.log(`\n🔧 Assigning user "${userToAssign.name}" (ID: ${userToAssign.id}) to warehouse ID 1`);
      
      await connection.execute(`
        UPDATE users SET warehouse_id = 1 WHERE id = ?
      `, [userToAssign.id]);
      
      console.log('✅ User assigned to warehouse successfully');
      
      // Verify the assignment
      const [updatedUser] = await connection.execute(`
        SELECT id, name, email, warehouse_id FROM users WHERE id = ?
      `, [userToAssign.id]);
      
      console.log('✅ Verification - Updated user:', updatedUser[0]);
    }

    // Show final warehouse assignments
    console.log('\n📋 Final warehouse assignments:');
    const [finalUsers] = await connection.execute(`
      SELECT u.id, u.name, u.email, u.warehouse_id, w.name as warehouse_name 
      FROM users u 
      LEFT JOIN warehouses w ON u.warehouse_id = w.id 
      ORDER BY u.id
    `);
    
    finalUsers.forEach(user => {
      const warehouseInfo = user.warehouse_name ? `Warehouse: ${user.warehouse_name}` : 'No warehouse';
      console.log(`  User ID: ${user.id}, Name: ${user.name} - ${warehouseInfo}`);
    });

    await connection.end();
    console.log('\n✅ Warehouse assignment fixed successfully!');
  } catch (error) {
    console.error('❌ Error fixing warehouse assignment:', error.message);
  }
}

fixWarehouseAssignment();





