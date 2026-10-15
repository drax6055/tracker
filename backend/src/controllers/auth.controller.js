const AuthService = require('../services/auth.service');
const ApiResponse = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');

class AuthController {
  static register = asyncHandler(async (req, res) => {
    const { name, email, password } = req.body;
    const result = await AuthService.register({ name, email, password });
    return ApiResponse.created(res, result, 'User registered successfully');
  });

  static login = asyncHandler(async (req, res) => {
    const { email, password, device } = req.body;
    const result = await AuthService.login({ email, password, device });
    return ApiResponse.success(res, result, 'Logged in successfully');
  });

  static refresh = asyncHandler(async (req, res) => {
    const { refreshToken, device } = req.body;
    const tokens = await AuthService.refreshTokens(refreshToken, device);
    return ApiResponse.success(res, { tokens }, 'Tokens refreshed successfully');
  });

  static logout = asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    await AuthService.logout(refreshToken);
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
