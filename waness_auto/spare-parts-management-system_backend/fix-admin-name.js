const mongoose = require('mongoose');
require('dotenv').config();

async function fixAdminName() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const db = mongoose.connection.db;
    const usersCollection = db.collection('users');

    // Update admin user to add name field
    const result = await usersCollection.updateOne(
      { email: 'admin@admin.com' },
      { 
        $set: { 
          name: 'Admin User'
        } 
      }
    );

    console.log('✅ Admin user updated:', result);

    // Verify the update
    const admin = await usersCollection.findOne({ email: 'admin@admin.com' });
    console.log('\n📄 Updated admin user:');
    console.log(JSON.stringify(admin, null, 2));

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

fixAdminName();
