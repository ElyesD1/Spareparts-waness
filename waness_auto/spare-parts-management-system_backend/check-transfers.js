const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'spare_parts_management1'
});

connection.query("SELECT id, status, product_id, from_warehouse_id, to_warehouse_id, created_at FROM product_transfers ORDER BY id DESC", (error, results) => {
  if (error) {
    console.error('Error:', error);
    process.exit(1);
  }
  
  console.log('All product transfers:');
  console.log('ID | Status | Product | From | To | Created');
  console.log('---|--------|---------|------|----|---------');
  
  results.forEach(row => {
    console.log(`${row.id} | ${row.status} | ${row.product_id} | ${row.from_warehouse_id} | ${row.to_warehouse_id} | ${row.created_at}`);
  });
  
  const pendingTransfers = results.filter(r => r.status === 'pending');
  console.log(`\nPending transfers: ${pendingTransfers.length}`);
  pendingTransfers.forEach(row => {
    console.log(`- Transfer ID ${row.id} is pending and can be approved/rejected`);
  });
  
  connection.end();
});
