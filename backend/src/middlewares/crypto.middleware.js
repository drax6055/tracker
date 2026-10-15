const { encryptPayload, decryptPayload } = require('../utils/crypto.util');

/**
 * Express middleware for transparent Request/Response encryption and decryption.
 * Handles GET, POST, PUT, DELETE.
 */
function cryptoMiddleware(req, res, next) {
  const isEncryptedHeader = req.headers['x-encrypted-payload'] === 'true';

  // 1. INCOMING REQUEST DECRYPTION
  if (req.body && (isEncryptedHeader || req.body._encrypted)) {
    try {
      req.body = decryptPayload(req.body);
      req.isPayloadEncrypted = true;
    } catch (err) {
      return res.status(400).json({
        success: false,
        message: 'Decryption failed: malformed ciphertext or invalid IV/key.',
      });
    }
  }

  // 2. OUTGOING RESPONSE ENCRYPTION
  const originalJson = res.json.bind(res);
  res.json = function (body) {
    if (isEncryptedHeader || req.isPayloadEncrypted) {
      try {
        res.setHeader('x-encrypted-payload', 'true');
        const encryptedBody = encryptPayload(body);
        return originalJson(encryptedBody);
      } catch (err) {
        console.error('[CryptoMiddleware] Outgoing encryption error:', err);
      }
    }
    return originalJson(body);
  };

  next();
}

module.exports = cryptoMiddleware;
