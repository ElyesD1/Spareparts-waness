require('dotenv').config();
const mongoose = require('mongoose');

async function fixAdminUser() {
  try {
    console.log('🔌 Connecting to MongoDB Atlas...');
    await mongoose.connect(process.env.MONGODB_URI, {
      retryWrites: true,
      w: 'majority',
    });
    
    console.log('✅ Connected successfully!\n');

    // Find the admin user with 'password' field and update it to 'password_hash'
    const result = await mongoose.connection.db.collection('users').updateOne(
      { email: 'admin@admin.com' },
      {
        $rename: { password: 'password_hash' }
      }
    );

    console.log('📝 Update result:', result);
    
    // Verify the fix
    const user = await mongoose.connection.db.collection('users').findOne({ email: 'admin@admin.com' });
    console.log('\n✅ Admin user after fix:');
    console.log('  Email:', user.email);
    console.log('  Has password_hash?', !!user.password_hash);
    console.log('  Has password?', !!user.password);
    console.log('  Role:', user.role);

    await mongoose.connection.close();
    console.log('\n✅ Fix completed successfully!');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

fixAdminUser();
