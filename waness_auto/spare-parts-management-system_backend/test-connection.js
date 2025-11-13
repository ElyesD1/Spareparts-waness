require('dotenv').config();
const mongoose = require('mongoose');

console.log('====== MongoDB Connection Test ======');
console.log('MONGODB_URI from env:', process.env.MONGODB_URI);
console.log('=====================================\n');

async function testConnection() {
  try {
    console.log('Attempting to connect to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI, {
      retryWrites: true,
      w: 'majority',
    });
    
    console.log('✅ Successfully connected to MongoDB Atlas!');
    console.log('Database name:', mongoose.connection.name);
    console.log('Host:', mongoose.connection.host);
    
    // List all collections
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('\n📦 Collections in database:');
    collections.forEach(col => {
      console.log('  -', col.name);
    });
    
    // List all databases
    const admin = mongoose.connection.db.admin();
    const { databases } = await admin.listDatabases();
    console.log('\n📚 All databases in cluster:');
    databases.forEach(db => {
      console.log('  -', db.name, `(${(db.sizeOnDisk / 1024 / 1024).toFixed(2)} MB)`);
    });
    
    await mongoose.connection.close();
    console.log('\n✅ Connection test completed successfully!');
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
    console.error('Full error:', error);
  }
}

testConnection();
