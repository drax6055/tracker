const crypto = require('crypto');
const env = require('../config/env');

// Master 256-bit encryption key (32 bytes)
const RAW_KEY = env.encryptionSecret || 'ledger_super_secret_32_bytes_key!';
const KEY = crypto.createHash('sha256').update(String(RAW_KEY)).digest();

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
 * Wrapper for API request/response payload encryption
 */
function encryptPayload(body) {
  const cipher = encrypt(body);
  return {
    _encrypted: true,
    iv: cipher.iv,
    data: cipher.data,
  };
}

/**
 * Wrapper for API request/response payload decryption
 */
function decryptPayload(reqBody) {
  if (!reqBody || typeof reqBody !== 'object') return reqBody;
  if (reqBody._encrypted && reqBody.iv && reqBody.data) {
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
