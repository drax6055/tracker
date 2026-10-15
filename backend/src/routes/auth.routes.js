const express = require('express');
const AuthController = require('../controllers/auth.controller');
const validate = require('../middlewares/validate.middleware');
const { protect } = require('../middlewares/auth.middleware');
const { authLimiter } = require('../middlewares/rateLimiter.middleware');
const {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  forgotPasswordSchema,
  verifyOtpSchema,
  resetPasswordSchema,
  changePasswordSchema,
} = require('../validations/auth.validation');

const router = express.Router();

router.post('/register', authLimiter, validate(registerSchema), AuthController.register);
router.post('/login', authLimiter, validate(loginSchema), AuthController.login);
router.post('/refresh', validate(refreshTokenSchema), AuthController.refresh);
router.post('/logout', AuthController.logout);

router.post('/forgot-password', authLimiter, validate(forgotPasswordSchema), AuthController.forgotPassword);
router.post('/verify-otp', authLimiter, validate(verifyOtpSchema), AuthController.verifyOtp);
router.post('/reset-password', authLimiter, validate(resetPasswordSchema), AuthController.resetPassword);

// Protected auth route
router.post('/change-password', protect, validate(changePasswordSchema), AuthController.changePassword);

module.exports = router;
