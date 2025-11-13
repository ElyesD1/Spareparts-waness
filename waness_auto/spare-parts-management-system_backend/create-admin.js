require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

// User Schema (matching your backend schema)
const UserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  firstName: { type: String, required: true },
  lastName: { type: String, required: true },
  role: { type: String, enum: ['admin', 'manager', 'user', 'guest'], default: 'user' },
  phoneNumber: String,
  warehouseId: { type: mongoose.Schema.Types.ObjectId, ref: 'Warehouse' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

async function createAdminUser() {
  try {
    console.log('🔌 Connecting to MongoDB Atlas...');
    console.log('URI:', process.env.MONGODB_URI.replace(/:[^:@]+@/, ':****@'));
    
    await mongoose.connect(process.env.MONGODB_URI, {
      retryWrites: true,
      w: 'majority',
    });
    
    console.log('✅ Connected successfully!\n');

    // Create User model
    const User = mongoose.model('User', UserSchema);

    // Check if admin already exists
    const existingAdmin = await User.findOne({ email: 'admin@admin.com' });
    if (existingAdmin) {
      console.log('⚠️  Admin user already exists!');
      console.log('Email:', existingAdmin.email);
      console.log('Role:', existingAdmin.role);
      await mongoose.connection.close();
      return;
    }

    // Hash password
    console.log('🔐 Hashing password...');
    const hashedPassword = await bcrypt.hash('beyblade77@', 10);

    // Create admin user
    console.log('👤 Creating admin user...');
    const adminUser = new User({
      email: 'admin@admin.com',
      password: hashedPassword,
      firstName: 'Admin',
      lastName: 'User',
      role: 'admin',
      phoneNumber: '+1234567890',
      createdAt: new Date(),
      updatedAt: new Date()
    });

    await adminUser.save();

    console.log('\n✅ Admin user created successfully!');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('📧 Email: admin@admin.com');
    console.log('🔑 Password: beyblade77@');
    console.log('👑 Role: admin');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    // List all collections
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('📦 Collections created in database:');
    collections.forEach(col => {
      console.log('  ✓', col.name);
    });

    // Verify databases
    const admin = mongoose.connection.db.admin();
    const { databases } = await admin.listDatabases();
    console.log('\n📚 All databases in cluster:');
    databases.forEach(db => {
      if (db.name === 'spare_parts_management') {
        console.log('  ✓', db.name, '<-- YOUR DATABASE!');
      } else {
        console.log('  -', db.name);
      }
    });

    console.log('\n🎉 Success! Now refresh MongoDB Atlas and select "spare_parts_management" database!\n');

    await mongoose.connection.close();
    console.log('✅ Connection closed.');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

createAdminUser();
