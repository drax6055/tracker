const AppError = require('../utils/appError');

const validate = (schema) => (req, res, next) => {
  try {
    const parsed = schema.parse(req.body);
    req.body = parsed;
    next();
  } catch (error) {
    if (error.errors) {
      const formattedErrors = error.errors.map((err) => ({
        field: err.path.join('.'),
        message: err.message,
      }));
      return next(new AppError('Validation failed', 400, formattedErrors));
    }
    return next(new AppError('Invalid request payload', 400));
  }
};

module.exports = validate;
