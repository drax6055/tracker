const crypto = require('crypto');
const env = require('../config/env');

// Master 256-bit encryption key (32 bytes)
if (env.env === 'production' && (!process.env.ENCRYPTION_SECRET || process.env.ENCRYPTION_SECRET === 'ledger_super_secret_32_bytes_key!')) {
  console.warn('[SECURITY WARNING] Using default fallback encryption key in production. Please set ENCRYPTION_SECRET in environment variables.');
}

const RAW_KEY = env.encryptionSecret || 'ledger_super_secret_32_bytes_key!';
const KEY = crypto.createHash('sha256').update(String(RAW_KEY)).digest();
// Derive distinct HMAC key from master secret for authenticated encryption (Encrypt-then-MAC)
const HMAC_KEY = crypto.createHmac('sha256', KEY).update('hmac-signature-salt').digest();

/**
 * Encrypt a plain string or JSON object using AES-256-CBC.
 * Returns { iv: string, data: string } in Base64 format.
 */
function encrypt(data) {
  if (data === null || data === undefined) return null;
  const text = typeof data === 'object' ? JSON.stringify(data) : String(data);
  const iv = crypto.randomBytes(16);
  const cipher = crypto.createCipheriv('aes-256-cbc', KEY, iv);

  let encrypted = cipher.update(text, 'utf8', 'base64');
  encrypted += cipher.final('base64');

  return {
    iv: iv.toString('base64'),
    data: encrypted,
  };
}

/**
 * Decrypt an AES-256-CBC Base64 payload back to its original JSON object or string.
 */
function decrypt({ iv, data }) {
  if (!iv || !data) return null;
  const ivBuffer = Buffer.from(iv, 'base64');
  const decipher = crypto.createDecipheriv('aes-256-cbc', KEY, ivBuffer);

  let decrypted = decipher.update(data, 'base64', 'utf8');
  decrypted += decipher.final('utf8');

  try {
    return JSON.parse(decrypted);
  } catch (_) {
    return decrypted;
  }
}

/**
 * Wrapper for API request/response payload encryption with HMAC integrity
 */
function encryptPayload(body) {
  const cipher = encrypt(body);
  const mac = crypto.createHmac('sha256', HMAC_KEY).update(`${cipher.iv}:${cipher.data}`).digest('base64');
  return {
    _encrypted: true,
    iv: cipher.iv,
    data: cipher.data,
    mac,
  };
}

/**
 * Wrapper for API request/response payload decryption with constant-time MAC verification
 */
function decryptPayload(reqBody) {
  if (!reqBody || typeof reqBody !== 'object') return reqBody;
  if (reqBody._encrypted && reqBody.iv && reqBody.data) {
    if (reqBody.mac) {
      const expectedMac = crypto.createHmac('sha256', HMAC_KEY).update(`${reqBody.iv}:${reqBody.data}`).digest('base64');
      const macBuffer = Buffer.from(reqBody.mac);
      const expectedBuffer = Buffer.from(expectedMac);
      if (macBuffer.length !== expectedBuffer.length || !crypto.timingSafeEqual(macBuffer, expectedBuffer)) {
        throw new Error('Message authentication failed: invalid MAC signature');
      }
    }
    return decrypt({ iv: reqBody.iv, data: reqBody.data });
  }
  return reqBody;
}

module.exports = {
  encrypt,
  decrypt,
  encryptPayload,
  decryptPayload,
  KEY,
};
