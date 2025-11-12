const mysql = require('mysql2/promise');
const { MongoClient } = require('mongodb');
require('dotenv').config();

// Configuration
const mysqlConfig = {
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'spare_parts_management1'
};

const mongodbUri = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const mongodbDatabase = 'spare_parts_management';

// Tables to migrate (in order to respect foreign keys)
const tables = [
  'warehouses',
  'suppliers',
  'users',
  'customers',
  'products',
  'product_stocks',
  'sales',
  'purchases',
  'sale_items',
  'purchase_items',
  'credit_sales',
  'credit_sale_items',
  'credit_payments',
  'stock_movements',
  'product_transfers',
  'purchase_returns',
  'purchase_return_items',
  'supplier_credits',
  'operational_expenses'
];

async function migrateData() {
  let mysqlConnection;
  let mongoClient;

  try {
    console.log('🔄 Starting MySQL to MongoDB migration...\n');

    // Connect to MySQL
    console.log('📊 Connecting to MySQL...');
    mysqlConnection = await mysql.createConnection(mysqlConfig);
    console.log('✅ MySQL connected\n');

    // Connect to MongoDB
    console.log('🍃 Connecting to MongoDB...');
    mongoClient = new MongoClient(mongodbUri);
    await mongoClient.connect();
    const mongoDb = mongoClient.db(mongodbDatabase);
    console.log('✅ MongoDB connected\n');

    // Mapping of MySQL ID to MongoDB ObjectId
    const idMappings = {};

    // Migrate each table
    for (const tableName of tables) {
      try {
        console.log(`\n📦 Migrating table: ${tableName}`);
        
        // Check if table exists
        const [tableExists] = await mysqlConnection.execute(
          `SHOW TABLES LIKE '${tableName}'`
        );
        
        if (tableExists.length === 0) {
          console.log(`⚠️  Table ${tableName} does not exist, skipping...`);
          continue;
        }

        // Get data from MySQL
        const [rows] = await mysqlConnection.execute(`SELECT * FROM \`${tableName}\``);
        
        if (rows.length === 0) {
          console.log(`   ℹ️  No data in ${tableName}`);
          continue;
        }

        console.log(`   Found ${rows.length} records`);

        // Get MongoDB collection
        const collection = mongoDb.collection(tableName);

        // Transform and insert data
        const transformedRows = rows.map(row => {
          const transformed = { ...row };

          // Store original MySQL ID mapping
          if (row.id) {
            if (!idMappings[tableName]) {
              idMappings[tableName] = {};
            }
          }

          // Convert dates
          Object.keys(transformed).forEach(key => {
            if (transformed[key] instanceof Date) {
              transformed[key] = new Date(transformed[key]);
            }
            
            // Convert foreign key references if they exist in mappings
            if (key.endsWith('_id') && transformed[key]) {
              const refTableName = key.replace('_id', 's'); // Simple pluralization
              if (idMappings[refTableName] && idMappings[refTableName][transformed[key]]) {
                transformed[`${key}_mongo`] = idMappings[refTableName][transformed[key]];
              }
            }
          });

          // Remove MySQL auto-increment ID (MongoDB will create _id)
          const originalId = transformed.id;
          delete transformed.id;

          return { originalId, doc: transformed };
        });

        // Insert documents
        const docs = transformedRows.map(t => t.doc);
        const result = await collection.insertMany(docs);

        // Store ID mappings
        if (!idMappings[tableName]) {
          idMappings[tableName] = {};
        }
        transformedRows.forEach((row, index) => {
          const insertedIds = Object.values(result.insertedIds);
          idMappings[tableName][row.originalId] = insertedIds[index];
        });

        console.log(`   ✅ Migrated ${result.insertedCount} documents to ${tableName}`);

      } catch (tableError) {
        console.error(`   ❌ Error migrating table ${tableName}:`, tableError.message);
      }
    }

    console.log('\n\n🎉 Migration completed successfully!');
    console.log('\n📊 Summary:');
    Object.keys(idMappings).forEach(table => {
      console.log(`   ${table}: ${Object.keys(idMappings[table]).length} records`);
    });

    console.log('\n⚠️  Important Next Steps:');
    console.log('1. Update your NestJS application to use Mongoose instead of TypeORM');
    console.log('2. Update your frontend to handle MongoDB ObjectIds instead of numeric IDs');
    console.log('3. Test all API endpoints thoroughly');
    console.log('4. Backup your MySQL database before removing it');

  } catch (error) {
    console.error('\n❌ Migration failed:', error);
  } finally {
    // Close connections
    if (mysqlConnection) {
      await mysqlConnection.end();
      console.log('\n🔌 MySQL connection closed');
    }
    if (mongoClient) {
      await mongoClient.close();
      console.log('🔌 MongoDB connection closed');
    }
  }
}

// Run migration
migrateData()
  .then(() => {
    console.log('\n✨ Migration script finished');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n💥 Fatal error:', error);
    process.exit(1);
  });
