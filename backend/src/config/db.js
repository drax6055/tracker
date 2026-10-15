const dns = require('dns');
try {
  dns.setServers(['8.8.8.8', '1.1.1.1']);
} catch (e) {
  // Ignore if custom dns servers cannot be set
}
const mongoose = require('mongoose');
const env = require('./env');

let cached = global.mongooseConnection;

if (!cached) {
  cached = global.mongooseConnection = { conn: null, promise: null };
}

const connectDB = async () => {
  if (cached.conn) {
    return cached.conn;
  }

  if (!cached.promise) {
    const opts = {
      autoIndex: true,
      serverSelectionTimeoutMS: 8000,
      driverInfo: { name: 'nodejs', version: '1.0.0' },
    };

    cached.promise = mongoose.connect(env.mongodbUri, opts).then((mongooseInstance) => {
      console.log(`[Database] MongoDB Connected: ${mongooseInstance.connection.host}/${mongooseInstance.connection.name}`);
      return mongooseInstance;
    });
  }

  try {
    cached.conn = await cached.promise;
  } catch (e) {
    cached.promise = null;
    console.error(`[Database Error] ${e.message}`);
    throw e;
  }

  return cached.conn;
};

module.exports = connectDB;
