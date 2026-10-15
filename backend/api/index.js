const app = require('../src/app');
const connectDB = require('../src/config/db');

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version, Authorization, x-encrypted-payload'
  );
  res.setHeader('Access-Control-Expose-Headers', 'x-encrypted-payload');

  // Handle CORS preflight immediately without touching DB
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  try {
    await connectDB();
    return app(req, res);
  } catch (error) {
    console.error('[Serverless Gateway Error]', error);
    return res.status(500).json({
      success: false,
      message: 'Database connection failed. Please verify MongoDB Atlas configuration.',
      error: error.message,
    });
  }
};
