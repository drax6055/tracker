const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const env = require('../config/env');
const RefreshToken = require('../models/refreshToken.model');

class TokenService {
  static generateAccessToken(user, deviceId = null) {
    const payload = {
      sub: user._id.toString(),
      email: user.email,
      name: user.name,
      currency: user.currency || 'INR',
      sessionVersion: user.sessionVersion || 1,
      deviceId: deviceId || user.currentDeviceId || null,
    };

    return jwt.sign(payload, env.jwt.accessSecret, {
      expiresIn: env.jwt.accessExpiresIn,
    });
  }

  static verifyAccessToken(token) {
    return jwt.verify(token, env.jwt.accessSecret);
  }

  static hashToken(token) {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  static async generateAuthTokens(user, device = 'mobile', deviceId = null) {
    const accessToken = this.generateAccessToken(user, deviceId);

    // 7 days expiration for refresh token
    const refreshTokenRaw = crypto.randomBytes(40).toString('hex');
    const tokenHash = this.hashToken(refreshTokenRaw);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await RefreshToken.create({
      userId: user._id,
      tokenHash,
      device,
      deviceId,
      expiresAt,
    });

    return {
      accessToken,
      refreshToken: refreshTokenRaw,
      expiresIn: 15 * 60, // 15 minutes in seconds
    };
  }

  static async verifyRefreshToken(refreshTokenRaw) {
    const tokenHash = this.hashToken(refreshTokenRaw);
    const tokenDoc = await RefreshToken.findOne({
      tokenHash,
      revoked: false,
      expiresAt: { $gt: new Date() },
    });

    return tokenDoc;
  }

  static async revokeRefreshToken(refreshTokenRaw) {
    const tokenHash = this.hashToken(refreshTokenRaw);
    await RefreshToken.updateOne({ tokenHash }, { $set: { revoked: true } });
  }

  static async revokeAllUserRefreshTokens(userId) {
    await RefreshToken.updateMany({ userId }, { $set: { revoked: true } });
  }
}

module.exports = TokenService;
