const rateLimit = require('express-rate-limit');

const generalLimiterInstance = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  message: {
    success: false,
    message: 'Too many requests from this IP, please try again after 15 minutes',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const authLimiterInstance = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  message: {
    success: false,
    message: 'Too many authentication attempts from this IP, please try again after 15 minutes',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const generalLimiter = (req, res, next) => {
  if (process.env.NODE_ENV === 'test') return next();
  return generalLimiterInstance(req, res, next);
};

const authLimiter = (req, res, next) => {
  if (process.env.NODE_ENV === 'test') return next();
  return authLimiterInstance(req, res, next);
};

module.exports = {
  generalLimiter,
  authLimiter,
};
