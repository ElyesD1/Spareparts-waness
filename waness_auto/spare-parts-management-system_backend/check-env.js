require('dotenv').config();

console.log('=================================');
console.log('Environment Variables Check');
console.log('=================================');
console.log('MONGODB_URI exists:', !!process.env.MONGODB_URI);
console.log('MONGODB_URI value:', process.env.MONGODB_URI);
console.log('MONGODB_URI length:', process.env.MONGODB_URI?.length);
console.log('=================================');

// Check if it contains Atlas
if (process.env.MONGODB_URI) {
  if (process.env.MONGODB_URI.includes('mongodb+srv')) {
    console.log('✅ Using MongoDB Atlas');
  } else if (process.env.MONGODB_URI.includes('localhost')) {
    console.log('❌ Using Local MongoDB');
  }
}

// List all env vars that contain 'MONGO'
console.log('\nAll MongoDB-related env vars:');
Object.keys(process.env).forEach(key => {
  if (key.toUpperCase().includes('MONGO')) {
    console.log(`  ${key}:`, process.env[key]);
  }
});
