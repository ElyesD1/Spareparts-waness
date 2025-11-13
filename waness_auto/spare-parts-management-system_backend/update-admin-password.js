const { MongoClient } = require('mongodb');
const bcrypt = require('bcrypt');
require('dotenv').config();

async function updateAdminPassword() {
  const client = new MongoClient(process.env.MONGODB_URI);

  try {
    await client.connect();
    console.log('✅ Connected to MongoDB...');
    
    const db = client.db();
    const usersCollection = db.collection('users');
    
    const newPassword = 'beyblade77@12345678901';
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    console.log(`\n🔐 New password hash: ${hashedPassword.substring(0, 20)}...`);
    
    // Update admin user password - update both password and password_hash fields
    const result = await usersCollection.updateOne(
      { role: 'admin' },
      { 
        $set: { 
          password: hashedPassword,
          password_hash: hashedPassword 
        } 
      }
    );
    
    if (result.matchedCount > 0) {
      console.log('✅ Admin password updated successfully!');
      console.log(`Email: admin@admin.com`);
      console.log(`New Password: ${newPassword}`);
      console.log(`Matched: ${result.matchedCount}, Modified: ${result.modifiedCount}`);
      
      // Verify the update
      const admin = await usersCollection.findOne({ role: 'admin' });
      console.log(`\n✔️  Verified - Password hash (first 20 chars): ${admin.password.substring(0, 20)}`);
    } else {
      console.log('❌ No admin user found');
    }
  } catch (error) {
    console.error('❌ Error updating admin password:', error);
  } finally {
    await client.close();
    console.log('\nDatabase connection closed.');
  }
}

updateAdminPassword();
