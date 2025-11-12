const mysql = require('mysql2/promise');

async function addDeletedAtColumnToProducts() {
  try {
    // Create connection
    const connection = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '',
      database: 'spare_parts_management1'
    });

    console.log('✅ Database connection successful');

    // Check if products table exists
    const [tables] = await connection.execute('SHOW TABLES LIKE "products"');
    if (tables.length === 0) {
      console.log('❌ Products table does not exist');
      return;
    }

    console.log('✅ Products table exists');

    // Check if deletedAt column already exists
    const [columns] = await connection.execute('DESCRIBE products');
    const deletedAtExists = columns.some(col => col.Field === 'deletedAt');
    
    if (deletedAtExists) {
      console.log('✅ deletedAt column already exists in products table');
      // Show current structure
      console.log('📋 Products table structure:');
      columns.forEach(col => {
        console.log(`  ${col.Field}: ${col.Type} ${col.Null === 'YES' ? 'NULL' : 'NOT NULL'} ${col.Default ? `DEFAULT ${col.Default}` : ''}`);
      });
    } else {
      console.log('⚠️  deletedAt column does not exist, adding it now...');
      
      // Add the deletedAt column
      await connection.execute('ALTER TABLE `products` ADD COLUMN `deletedAt` datetime(6) NULL');
      console.log('✅ Successfully added deletedAt column to products table');
      
      // Create index for better performance
      try {
        await connection.execute('CREATE INDEX `IDX_products_deletedAt` ON `products` (`deletedAt`)');
        console.log('✅ Successfully created index on deletedAt column');
      } catch (indexError) {
        if (indexError.code === 'ER_DUP_KEYNAME') {
          console.log('ℹ️  Index already exists on deletedAt column');
        } else {
          console.log('⚠️  Could not create index:', indexError.message);
        }
      }
      
      // Verify the column was added
      const [newColumns] = await connection.execute('DESCRIBE products');
      const newDeletedAtExists = newColumns.some(col => col.Field === 'deletedAt');
      
      if (newDeletedAtExists) {
        console.log('✅ Verification successful: deletedAt column exists');
        console.log('📋 Updated products table structure:');
        newColumns.forEach(col => {
          console.log(`  ${col.Field}: ${col.Type} ${col.Null === 'YES' ? 'NULL' : 'NOT NULL'} ${col.Default ? `DEFAULT ${col.Default}` : ''}`);
        });
      } else {
        console.log('❌ Verification failed: deletedAt column was not added');
      }
    }

    await connection.end();
    console.log('🔄 Database connection closed');
  } catch (error) {
    console.error('❌ Database operation failed:', error.message);
    console.error('Full error:', error);
  }
}

addDeletedAtColumnToProducts();