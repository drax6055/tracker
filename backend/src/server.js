const app = require('./app');
const connectDB = require('./config/db');
const env = require('./config/env');

const startServer = async () => {
  await connectDB();

  const server = app.listen(env.port, '0.0.0.0', () => {
    console.log(`===============================================`);
    console.log(`  ⚡ LEDGER API Server running in ${env.env} mode`);
    console.log(`  🌐 Local:   http://localhost:${env.port}`);
    console.log(`  📱 Network: http://192.168.29.241:${env.port}`);
    console.log(`  📡 API Base: http://192.168.29.241:${env.port}/api/v1`);
    console.log(`===============================================`);
  });

  // Handle unhandled promise rejections
  process.on('unhandledRejection', (err) => {
    console.error('UNHANDLED REJECTION! Shutting down...', err.name, err.message);
    server.close(() => {
      process.exit(1);
    });
  });

  // Handle uncaught exceptions
  process.on('uncaughtException', (err) => {
    console.error('UNCAUGHT EXCEPTION! Shutting down...', err.name, err.message);
    process.exit(1);
  });
};

if (require.main === module) {
  startServer();
}

module.exports = startServer;
