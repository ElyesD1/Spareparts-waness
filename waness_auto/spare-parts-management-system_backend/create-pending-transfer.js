const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'spare_parts_management1'
});

// First, let's check if there are any pending transfers
connection.query("SELECT * FROM product_transfers WHERE status = 'pending'", (error, results) => {
  if (error) {
    console.error('Error:', error);
    process.exit(1);
  }
  
  console.log('Pending transfers:', results.length);
  
  if (results.length === 0) {
    console.log('No pending transfers found. Creating a new one for testing...');
    
    // Create a new pending transfer for testing
    const insertQuery = `
      INSERT INTO product_transfers 
      (product_id, from_warehouse_id, to_warehouse_id, quantity, status, priority, reason, requested_by, created_at, updated_at) 
      VALUES (1, 1, 2, 10, 'pending', 'normal', 'Test transfer for approval', 1, NOW(), NOW())
    `;
    
    connection.query(insertQuery, (insertError, insertResults) => {
      if (insertError) {
        console.error('Error creating transfer:', insertError);
        process.exit(1);
      }
      
      console.log('Created new pending transfer with ID:', insertResults.insertId);
      
      // Show all transfers again
      connection.query('SELECT id, status, product_id, from_warehouse_id, to_warehouse_id FROM product_transfers ORDER BY id DESC', (error2, results2) => {
        if (error2) {
          console.error('Error:', error2);
          process.exit(1);
        }
        
        console.log('\nAll transfers:');
        console.log('ID | Status | Product | From | To');
        console.log('---|--------|---------|------|----');
        
        results2.forEach(row => {
          console.log(`${row.id} | ${row.status} | ${row.product_id} | ${row.from_warehouse_id} | ${row.to_warehouse_id}`);
        });
        
        connection.end();
      });
    });
  } else {
    console.log('Found pending transfers:');
    results.forEach(row => {
      console.log(`ID: ${row.id}, Status: ${row.status}, Product: ${row.product_id}`);
    });
    connection.end();
  }
});
