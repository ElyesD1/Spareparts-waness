const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// MongoDB connection string - update this with your actual connection string
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/spare_parts_management';

// User Schema
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password_hash: { type: String, required: true },
  phone_number: { type: Number, required: true, unique: true },
  role: { 
    type: String, 
    required: true, 
    enum: ['admin', 'manager', 'cashier', 'guest'],
    default: 'cashier'
  },
  warehouse_id: { type: mongoose.Schema.Types.ObjectId, ref: 'Warehouse', default: null }
}, { 
  collection: 'users', 
  timestamps: true 
});

const User = mongoose.model('User', userSchema);

async function createAdminUser() {
  try {
    // Connect to MongoDB
    console.log('Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB successfully');

    // Check if user already exists
    const existingUser = await User.findOne({ email: 'admin@admin.com' });
    if (existingUser) {
      console.log('Admin user already exists!');
      console.log('User details:', {
        id: existingUser._id,
        name: existingUser.name,
        email: existingUser.email,
        role: existingUser.role,
        phone_number: existingUser.phone_number
      });
      await mongoose.connection.close();
      return;
    }

    // Hash the password
    console.log('Hashing password...');
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('beyblade77@', salt);

    // Create the admin user
    console.log('Creating admin user...');
    const adminUser = new User({
      name: 'Admin',
      email: 'admin@admin.com',
      password_hash: hashedPassword,
      phone_number: 12345678, // Default phone number, you can change this
      role: 'admin',
      warehouse_id: null
    });

    await adminUser.save();
    console.log('Admin user created successfully!');
    console.log('User details:', {
      id: adminUser._id,
      name: adminUser.name,
      email: adminUser.email,
      role: adminUser.role,
      phone_number: adminUser.phone_number
    });

    // Close the connection
    await mongoose.connection.close();
    console.log('Connection closed');
  } catch (error) {
    console.error('Error creating admin user:', error);
    if (mongoose.connection.readyState === 1) {
      await mongoose.connection.close();
    }
    process.exit(1);
  }
}

// Run the function
createAdminUser();
