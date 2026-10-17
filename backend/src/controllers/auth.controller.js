const AuthService = require('../services/auth.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

class AuthController {
  static register = asyncHandler(async (req, res) => {
    let { name, email, password, device, deviceId } = req.body;
    if (!device) {
      const ua = req.headers['user-agent'] || '';
      if (/mobile|android|iphone|ipad/i.test(ua)) {
        device = 'Mobile Device';
      } else if (/chrome|safari|firefox|edge|opera/i.test(ua)) {
        device = 'Web Browser';
      } else {
        device = 'Personal Device';
      }
    }
    if (!deviceId) {
      deviceId = `dev_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    }
    const result = await AuthService.register({ name, email, password, device, deviceId });
    return ApiResponse.created(res, result, 'User registered successfully');
  });

  static login = asyncHandler(async (req, res) => {
    let { email, password, device, deviceId, force } = req.body;
    if (!device) {
      const ua = req.headers['user-agent'] || '';
      if (/mobile|android|iphone|ipad/i.test(ua)) {
        device = 'Mobile Device';
      } else if (/chrome|safari|firefox|edge|opera/i.test(ua)) {
        device = 'Web Browser';
      } else {
        device = 'Personal Device';
      }
    }
    if (!deviceId) {
      deviceId = `dev_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    }
    const result = await AuthService.login({ email, password, device, deviceId, force });
    return ApiResponse.success(res, result, 'Logged in successfully');
  });

  static refresh = asyncHandler(async (req, res) => {
    const { refreshToken, device, deviceId } = req.body;
    const tokens = await AuthService.refreshTokens(refreshToken, device, deviceId);
    return ApiResponse.success(res, { tokens }, 'Tokens refreshed successfully');
  });

  static logout = asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    await AuthService.logout(refreshToken, req.user?._id);
    return ApiResponse.success(res, null, 'Logged out successfully');
  });

  static forgotPassword = asyncHandler(async (req, res) => {
    const { email } = req.body;
    const result = await AuthService.forgotPassword(email);
    return ApiResponse.success(res, null, result.message);
  });

  static verifyOtp = asyncHandler(async (req, res) => {
    const { email, otp } = req.body;
    const result = await AuthService.verifyOtp({ email, otp });
    return ApiResponse.success(res, { resetToken: result.resetToken }, result.message);
  });

  static resetPassword = asyncHandler(async (req, res) => {
    const { email, resetToken, newPassword } = req.body;
    const result = await AuthService.resetPassword({ email, resetToken, newPassword });
    return ApiResponse.success(res, null, result.message);
  });

  static changePassword = asyncHandler(async (req, res) => {
    const { currentPassword, newPassword } = req.body;
    const result = await AuthService.changePassword(req.user._id, { currentPassword, newPassword });
    return ApiResponse.success(res, { tokens: result.tokens }, result.message);
  });
}

module.exports = AuthController;
