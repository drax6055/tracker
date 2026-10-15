const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const routes = require('./routes');
const errorHandler = require('./middlewares/error.middleware');
const { generalLimiter } = require('./middlewares/rateLimiter.middleware');
const cryptoMiddleware = require('./middlewares/crypto.middleware');
const AppError = require('./utils/appError');
const env = require('./config/env');

const app = express();

// Security HTTP headers
app.use(helmet());

// Enable CORS
app.use(
  cors({
    origin: '*',
    credentials: true,
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'x-encrypted-payload',
      'Accept',
      'X-Requested-With',
    ],
    exposedHeaders: ['x-encrypted-payload'],
  })
);

// Apply rate limiting
app.use(generalLimiter);

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Custom E2E Payload Decryption & Encryption Middleware
app.use(cryptoMiddleware);

// Data sanitization against NoSQL query injection (Express 5 compatible)
app.use((req, res, next) => {
  if (req.body) req.body = mongoSanitize.sanitize(req.body);
  if (req.params) req.params = mongoSanitize.sanitize(req.params);
  next();
});

// API Routes
app.use('/api/v1', routes);

// Handle 404 unhandled routes
app.use((req, res, next) => {
  next(new AppError(`Cannot find ${req.method} ${req.originalUrl} on this server!`, 404));
});

// Centralized Error Handling Middleware
app.use(errorHandler);

module.exports = app;
