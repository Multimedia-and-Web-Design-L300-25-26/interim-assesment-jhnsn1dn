const mongoose = require('mongoose');

const connectDB = async () => {
  const uri = process.env.MONGODB_URI;

  // Basic validation: if URI is missing or looks like the placeholder from the .env file,
  // skip attempting to connect. This prevents the app from exiting immediately
  // in development when the environment isn't configured yet.
  if (!uri || uri.includes('<') || uri.includes('your_')) {
    console.warn('⚠️ MONGODB_URI is not set or looks like a placeholder. Skipping DB connection.');
    return null;
  }

  try {
    const conn = await mongoose.connect(uri);
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    return conn;
  } catch (error) {
    console.error(`❌ MongoDB connection error: ${error.message}`);
    // Don't exit the process here; allow the server to start so other non-DB
    // functionality can be developed/tested locally.
    return null;
  }
};

module.exports = connectDB;
