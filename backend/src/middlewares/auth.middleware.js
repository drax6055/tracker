const TokenService = require('../services/token.service');
const User = require('../models/user.model');
const AppError = require('../utils/appError');
const asyncHandler = require('../utils/asyncHandler');

const protect = asyncHandler(async (req, res, next) => {
  let token;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return next(new AppError('You are not logged in. Please provide an authentication token.', 401));
  }

  try {
    const decoded = TokenService.verifyAccessToken(token);

    const user = await User.findById(decoded.sub);
    if (!user) {
      return next(new AppError('The user belonging to this token no longer exists.', 401));
    }

    // Check if session has been revoked by another device login
    if (
      user.sessionVersion &&
      decoded.sessionVersion !== undefined &&
      decoded.sessionVersion < user.sessionVersion
    ) {
      return next(
        new AppError(
          'Your account has been logged in on another device. Please log in again.',
          401,
          null,
          'SESSION_REVOKED'
        )
      );
    }

    if (
      user.currentDeviceId &&
      decoded.deviceId &&
      decoded.deviceId !== user.currentDeviceId
    ) {
      return next(
        new AppError(
          'Your account has been logged in on another device. Please log in again.',
          401,
          null,
          'SESSION_REVOKED'
        )
      );
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return next(new AppError('Access token expired. Please refresh your token.', 401));
    }
    return next(new AppError('Invalid token. Please authenticate again.', 401));
  }
});

module.exports = {
  protect,
};
