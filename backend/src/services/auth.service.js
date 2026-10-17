const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const User = require('../models/user.model');
const RefreshToken = require('../models/refreshToken.model');
const PasswordResetOtp = require('../models/passwordResetOtp.model');
const TokenService = require('./token.service');
const EmailService = require('./email.service');
const AppError = require('../utils/appError');

class AuthService {
  static async register({ name, email, password, device = 'mobile', deviceId = null }) {
    const existing = await User.findOne({ email });
    if (existing) {
      throw new AppError('An account with this email already exists', 409);
    }

    const effectiveDeviceId =
      deviceId || `dev_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;

    const user = await User.create({
      name,
      email,
      password,
      currentDeviceId: effectiveDeviceId,
      currentDeviceName: device,
      sessionVersion: 1,
    });

    const tokens = await TokenService.generateAuthTokens(user, device, effectiveDeviceId);

    return {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        currency: user.currency,
        currencySymbol: user.currencySymbol,
        createdAt: user.createdAt,
      },
      tokens,
    };
  }

  static async login({ email, password, device = 'mobile', deviceId = null, force = false }) {
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      throw new AppError('Invalid email or password', 401);
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      throw new AppError('Invalid email or password', 401);
    }

    const effectiveDeviceId =
      deviceId || `dev_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;

    // Check if user already has an active session on another device
    if (!force) {
      // 1. Check user record currentDeviceId
      const hasActiveDeviceOnUser =
        user.currentDeviceId &&
        user.currentDeviceId !== effectiveDeviceId;

      // 2. Check active non-revoked refresh token in DB
      const activeSession = await RefreshToken.findOne({
        userId: user._id,
        revoked: false,
        expiresAt: { $gt: new Date() },
      }).sort({ updatedAt: -1 });

      const hasActiveSessionInTokens =
        activeSession &&
        activeSession.deviceId &&
        activeSession.deviceId !== effectiveDeviceId;

      if (hasActiveDeviceOnUser || hasActiveSessionInTokens) {
        const activeDeviceName =
          user.currentDeviceName ||
          (activeSession && activeSession.device) ||
          'another device';

        throw new AppError(
          `Account is already logged in on ${activeDeviceName}.`,
          409,
          null,
          'ACTIVE_SESSION_EXISTS',
          {
            activeDevice: activeDeviceName,
            lastActive: (activeSession && (activeSession.updatedAt || activeSession.createdAt)) || user.updatedAt,
          }
        );
      }
    }

    // Terminate all previous sessions and bump sessionVersion to immediately invalidate older tokens
    user.sessionVersion = (user.sessionVersion || 0) + 1;
    user.currentDeviceId = effectiveDeviceId;
    user.currentDeviceName = device || 'Personal Device';
    await user.save();

    // Revoke all prior refresh tokens for this user
    await TokenService.revokeAllUserRefreshTokens(user._id);

    const tokens = await TokenService.generateAuthTokens(user, user.currentDeviceName, effectiveDeviceId);

    return {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        currency: user.currency,
        currencySymbol: user.currencySymbol,
        createdAt: user.createdAt,
      },
      tokens,
    };
  }

  static async refreshTokens(refreshTokenRaw, device = 'mobile', deviceId = null) {
    const tokenDoc = await TokenService.verifyRefreshToken(refreshTokenRaw);
    if (!tokenDoc) {
      throw new AppError('Invalid or expired refresh token. Please login again.', 401, null, 'SESSION_REVOKED');
    }

    const user = await User.findById(tokenDoc.userId);
    if (!user) {
      throw new AppError('User not found', 404);
    }

    const effectiveDeviceId = deviceId || tokenDoc.deviceId;
    if (user.currentDeviceId && effectiveDeviceId && user.currentDeviceId !== effectiveDeviceId) {
      await TokenService.revokeRefreshToken(refreshTokenRaw);
      throw new AppError(
        'Your session was terminated because your account was logged in on another device.',
        401,
        null,
        'SESSION_REVOKED'
      );
    }

    // Revoke old refresh token for token rotation
    await TokenService.revokeRefreshToken(refreshTokenRaw);

    const newTokens = await TokenService.generateAuthTokens(
      user,
      device || tokenDoc.device || user.currentDeviceName,
      effectiveDeviceId || user.currentDeviceId
    );
    return newTokens;
  }

  static async logout(refreshTokenRaw, userId = null) {
    if (refreshTokenRaw) {
      const tokenDoc = await RefreshToken.findOne({
        tokenHash: TokenService.hashToken(refreshTokenRaw),
      });
      if (tokenDoc) {
        if (!userId) userId = tokenDoc.userId;
        await TokenService.revokeRefreshToken(refreshTokenRaw);
      }
    }
    if (userId) {
      await User.findByIdAndUpdate(userId, {
        $set: { currentDeviceId: null, currentDeviceName: null },
        $inc: { sessionVersion: 1 },
      });
      await TokenService.revokeAllUserRefreshTokens(userId);
    }
  }

  static async forgotPassword(email) {
    const user = await User.findOne({ email });
    if (!user) {
      // Don't disclose user existence for security, return positive message
      return { message: 'If an account with that email exists, an OTP has been sent.' };
    }

    // Invalidate existing active OTPs for this email
    await PasswordResetOtp.deleteMany({ email });

    // Generate 6-digit cryptographically secure OTP
    const otp = Math.floor(100000 + crypto.randomInt(900000)).toString();
    const salt = await bcrypt.genSalt(8);
    const otpHash = await bcrypt.hash(otp, salt);

    // 10 minutes expiry
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await PasswordResetOtp.create({
      email,
      otpHash,
      attempts: 0,
      maxAttempts: 5,
      expiresAt,
    });

    // Send email
    await EmailService.sendOtpEmail(email, otp);

    return { message: 'OTP sent to your registered email address' };
  }

  static async verifyOtp({ email, otp }) {
    const otpRecord = await PasswordResetOtp.findOne({
      email,
      expiresAt: { $gt: new Date() },
    });

    if (!otpRecord) {
      throw new AppError('OTP expired or not found. Please request a new one.', 400);
    }

    if (otpRecord.attempts >= otpRecord.maxAttempts) {
      await PasswordResetOtp.deleteOne({ _id: otpRecord._id });
      throw new AppError('Too many failed attempts. Please request a new OTP.', 429);
    }

    const isMatch = await bcrypt.compare(otp, otpRecord.otpHash);
    if (!isMatch) {
      otpRecord.attempts += 1;
      await otpRecord.save();
      const remaining = otpRecord.maxAttempts - otpRecord.attempts;
      throw new AppError(`Invalid OTP. ${remaining} attempt(s) remaining.`, 400);
    }

    // Mark verified and generate single-use resetToken
    const resetToken = crypto.randomBytes(32).toString('hex');
    otpRecord.isVerified = true;
    otpRecord.resetToken = resetToken;
    await otpRecord.save();

    return {
      message: 'OTP verified successfully',
      resetToken,
    };
  }

  static async resetPassword({ email, resetToken, newPassword }) {
    const otpRecord = await PasswordResetOtp.findOne({
      email,
      resetToken,
      isVerified: true,
      expiresAt: { $gt: new Date() },
    });

    if (!otpRecord) {
      throw new AppError('Invalid or expired reset session. Please restart password recovery.', 400);
    }

    const user = await User.findOne({ email });
    if (!user) {
      throw new AppError('User not found', 404);
    }

    user.password = newPassword;
    await user.save();

    // Invalidate the OTP session
    await PasswordResetOtp.deleteMany({ email });

    // Invalidate all refresh tokens after reset (as required in spec)
    await TokenService.revokeAllUserRefreshTokens(user._id);

    return { message: 'Password has been reset successfully. Please login with your new password.' };
  }

  static async changePassword(userId, { currentPassword, newPassword }) {
    const user = await User.findById(userId).select('+password');
    if (!user) {
      throw new AppError('User not found', 404);
    }

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      throw new AppError('Current password is incorrect', 400);
    }

    user.password = newPassword;
    await user.save();

    // Revoke previous refresh tokens
    await TokenService.revokeAllUserRefreshTokens(userId);

    // Issue fresh tokens
    const tokens = await TokenService.generateAuthTokens(user);

    return {
      message: 'Password changed successfully',
      tokens,
    };
  }
}

module.exports = AuthService;
