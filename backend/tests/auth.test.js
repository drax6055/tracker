process.env.NODE_ENV = 'test';
jest.setTimeout(30000);

const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../src/app');
const User = require('../src/models/user.model');
const RefreshToken = require('../src/models/refreshToken.model');
const PasswordResetOtp = require('../src/models/passwordResetOtp.model');
const env = require('../src/config/env');

beforeAll(async () => {
  // Connect to test database
  const testDbUri = env.mongodbUri.replace('ledger_db', 'ledger_test_db');
  await mongoose.connect(testDbUri, {
    serverSelectionTimeoutMS: 10000,
    driverInfo: { name: 'nodejs', version: '1.0.0' },
  });
});

beforeEach(async () => {
  await User.deleteMany({});
  await RefreshToken.deleteMany({});
  await PasswordResetOtp.deleteMany({});
});

afterAll(async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
});

describe('Authentication API Tests', () => {
  const validUser = {
    name: 'Bruce Wayne',
    email: 'bruce@wayne.corp',
    password: 'Batman123!',
    confirmPassword: 'Batman123!',
  };

  test('POST /api/v1/auth/register - Should register a new user successfully', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send(validUser);

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user).toBeDefined();
    expect(res.body.data.user.email).toBe(validUser.email);
    expect(res.body.data.tokens.accessToken).toBeDefined();
    expect(res.body.data.tokens.refreshToken).toBeDefined();
    expect(res.body.data.user.password).toBeUndefined();
  });

  test('POST /api/v1/auth/register - Should reject registration if passwords do not match', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        ...validUser,
        confirmPassword: 'DifferentPassword123',
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('POST /api/v1/auth/register - Should reject password without number or letter', async () => {
    const res = await request(app)
      .post('/api/v1/auth/register')
      .send({
        ...validUser,
        password: 'onlyletters',
        confirmPassword: 'onlyletters',
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('POST /api/v1/auth/login - Should log in with valid credentials', async () => {
    await request(app).post('/api/v1/auth/register').send(validUser);

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: validUser.email,
        password: validUser.password,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.tokens.accessToken).toBeDefined();
  });

  test('POST /api/v1/auth/login - Should reject invalid password', async () => {
    await request(app).post('/api/v1/auth/register').send(validUser);

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        email: validUser.email,
        password: 'WrongPassword99',
      });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  test('POST /api/v1/auth/refresh - Should issue new access & refresh tokens', async () => {
    const regRes = await request(app).post('/api/v1/auth/register').send(validUser);
    const oldRefreshToken = regRes.body.data.tokens.refreshToken;

    const res = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: oldRefreshToken });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.tokens.accessToken).toBeDefined();
    expect(res.body.data.tokens.refreshToken).toBeDefined();
    expect(res.body.data.tokens.refreshToken).not.toBe(oldRefreshToken);
  });

  test('GET /api/v1/user/me - Protected route access with valid Bearer token', async () => {
    const regRes = await request(app).post('/api/v1/auth/register').send(validUser);
    const token = regRes.body.data.tokens.accessToken;

    const res = await request(app)
      .get('/api/v1/user/me')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.email).toBe(validUser.email);
  });

  test('POST /api/v1/auth/logout - Should revoke the refresh token', async () => {
    const regRes = await request(app).post('/api/v1/auth/register').send(validUser);
    const refreshToken = regRes.body.data.tokens.refreshToken;

    const logoutRes = await request(app)
      .post('/api/v1/auth/logout')
      .send({ refreshToken });

    expect(logoutRes.status).toBe(200);
    expect(logoutRes.body.success).toBe(true);

    // Refreshing with revoked token should fail
    const refreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });

    expect(refreshRes.status).toBe(401);
  });

  test('Forgot Password Flow: Request OTP -> Verify OTP -> Reset Password -> Login with new password', async () => {
    const EmailService = require('../src/services/email.service');
    let capturedOtp = null;
    jest.spyOn(EmailService, 'sendOtpEmail').mockImplementation(async (email, otp) => {
      capturedOtp = otp;
      return { messageId: 'test-id' };
    });

    await request(app).post('/api/v1/auth/register').send(validUser);

    // 1. Request OTP
    const forgotRes = await request(app)
      .post('/api/v1/auth/forgot-password')
      .send({ email: validUser.email });

    expect(forgotRes.status).toBe(200);
    expect(capturedOtp).toBeDefined();
    expect(capturedOtp).toHaveLength(6);

    // 2. Test invalid OTP
    const invalidOtpRes = await request(app)
      .post('/api/v1/auth/verify-otp')
      .send({ email: validUser.email, otp: '000000' });
    expect(invalidOtpRes.status).toBe(400);

    // 3. Test valid OTP
    const verifyRes = await request(app)
      .post('/api/v1/auth/verify-otp')
      .send({ email: validUser.email, otp: capturedOtp });

    expect(verifyRes.status).toBe(200);
    expect(verifyRes.body.success).toBe(true);
    const { resetToken } = verifyRes.body.data;
    expect(resetToken).toBeDefined();

    // 4. Reset Password
    const newPassword = 'NewBatmanSecret2026!';
    const resetRes = await request(app)
      .post('/api/v1/auth/reset-password')
      .send({
        email: validUser.email,
        resetToken,
        newPassword,
        confirmPassword: newPassword,
      });

    expect(resetRes.status).toBe(200);
    expect(resetRes.body.success).toBe(true);

    // 5. Login with old password must fail
    const oldLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: validUser.email, password: validUser.password });
    expect(oldLoginRes.status).toBe(401);

    // 6. Login with new password must succeed
    const newLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: validUser.email, password: newPassword });
    expect(newLoginRes.status).toBe(200);
    expect(newLoginRes.body.success).toBe(true);
  });

  test('POST /api/v1/auth/change-password - Should change password and invalidate previous tokens', async () => {
    const regRes = await request(app).post('/api/v1/auth/register').send(validUser);
    const { accessToken, refreshToken } = regRes.body.data.tokens;

    const newPassword = 'UpdatedPassword99!';
    const changeRes = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        currentPassword: validUser.password,
        newPassword,
        confirmPassword: newPassword,
      });

    expect(changeRes.status).toBe(200);
    expect(changeRes.body.success).toBe(true);
    expect(changeRes.body.data.tokens.accessToken).toBeDefined();

    // Old refresh token should now be invalidated
    const oldRefreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });
    expect(oldRefreshRes.status).toBe(401);
  });
});
