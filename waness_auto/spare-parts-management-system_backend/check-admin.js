const { MongoClient } = require('mongodb');
require('dotenv').config();

async function checkAdmin() {
  const client = new MongoClient(process.env.MONGODB_URI);

  try {
    await client.connect();
    console.log('✅ Connected to MongoDB...');
    
    const db = client.db();
    const usersCollection = db.collection('users');
    
    // Find all admin users
    const admins = await usersCollection.find({ role: 'admin' }).toArray();
    
    console.log('\n📋 Admin users found:', admins.length);
    admins.forEach((user, index) => {
      console.log(`\n--- Admin ${index + 1} ---`);
      console.log(`ID: ${user._id}`);
      console.log(`Username: ${user.username}`);
      console.log(`Email: ${user.email}`);
      console.log(`Role: ${user.role}`);
      console.log(`Password Hash (first 20 chars): ${user.password ? user.password.substring(0, 20) : 'N/A'}`);
      console.log(`Full user object:`, JSON.stringify(user, null, 2));
    });
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
  }
}

checkAdmin();
