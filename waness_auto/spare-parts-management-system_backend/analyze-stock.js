const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'spare_parts_management1'
});

console.log('=== Product Stock Analysis ===\n');

// Check current product stocks
connection.query(`
  SELECT ps.*, p.name as product_name, w.name as warehouse_name 
  FROM product_stocks ps
  LEFT JOIN products p ON ps.product_id = p.id
  LEFT JOIN warehouses w ON ps.warehouse_id = w.id
  ORDER BY ps.product_id, ps.warehouse_id
`, (error, stocks) => {
  if (error) {
    console.error('Error fetching stocks:', error);
    process.exit(1);
  }
  
  console.log('Current Product Stocks:');
  console.log('Product | Warehouse | Quantity');
  console.log('--------|-----------|----------');
  stocks.forEach(stock => {
    console.log(`${stock.product_name || stock.product_id} | ${stock.warehouse_name || stock.warehouse_id} | ${stock.quantity}`);
  });
  
  // Check recent transfers
  connection.query(`
    SELECT pt.*, p.name as product_name, 
           fw.name as from_warehouse, tw.name as to_warehouse
    FROM product_transfers pt
    LEFT JOIN products p ON pt.product_id = p.id
    LEFT JOIN warehouses fw ON pt.from_warehouse_id = fw.id
    LEFT JOIN warehouses tw ON pt.to_warehouse_id = tw.id
    ORDER BY pt.id DESC
  `, (error2, transfers) => {
    if (error2) {
      console.error('Error fetching transfers:', error2);
      process.exit(1);
    }
    
    console.log('\nRecent Transfers:');
    console.log('ID | Product | From | To | Qty | Status | Approved | Processed');
    console.log('---|---------|------|----|----|--------|----------|----------');
    transfers.forEach(transfer => {
      console.log(`${transfer.id} | ${transfer.product_name || transfer.product_id} | ${transfer.from_warehouse || transfer.from_warehouse_id} | ${transfer.to_warehouse || transfer.to_warehouse_id} | ${transfer.quantity} | ${transfer.status} | ${transfer.approved_at ? 'Yes' : 'No'} | ${transfer.processed_at ? 'Yes' : 'No'}`);
    });
    
    // Check stock movements
    connection.query(`
      SELECT sm.*, p.name as product_name, w.name as warehouse_name
      FROM stock_movements sm
      LEFT JOIN products p ON sm.product_id = p.id
      LEFT JOIN warehouses w ON sm.warehouse_id = w.id
      WHERE sm.reference_type = 'transfer'
      ORDER BY sm.created_at DESC
      LIMIT 10
    `, (error3, movements) => {
      if (error3) {
        console.error('Error fetching movements:', error3);
        process.exit(1);
      }
      
      console.log('\nRecent Transfer-Related Stock Movements:');
      console.log('Product | Warehouse | Type | Quantity | Reason');
      console.log('--------|-----------|------|----------|--------');
      movements.forEach(movement => {
        console.log(`${movement.product_name || movement.product_id} | ${movement.warehouse_name || movement.warehouse_id} | ${movement.movement_type} | ${movement.quantity} | ${movement.reason}`);
      });
      
      connection.end();
    });
  });
});
