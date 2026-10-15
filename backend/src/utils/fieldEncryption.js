const { encrypt, decrypt } = require('./crypto.util');

const ENC_PREFIX = 'enc:';

/**
 * Encrypt a field value to formatted string: 'enc:<iv>:<ciphertext>'
 */
function encryptField(val) {
  if (!val || typeof val !== 'string') return val;
  if (val.startsWith(ENC_PREFIX)) return val; // Already encrypted

  const cipher = encrypt(val);
  return `${ENC_PREFIX}${cipher.iv}:${cipher.data}`;
}

/**
 * Decrypt a formatted string: 'enc:<iv>:<ciphertext>'
 */
function decryptField(val) {
  if (!val || typeof val !== 'string') return val;
  if (!val.startsWith(ENC_PREFIX)) return val; // Not encrypted

  const parts = val.slice(ENC_PREFIX.length).split(':');
  if (parts.length !== 2) return val;

  const [iv, data] = parts;
  try {
    return decrypt({ iv, data });
  } catch (err) {
    return val;
  }
}

/**
 * Mongoose Plugin for Transparent Field-Level Database Encryption.
 * Usage:
 *   schema.plugin(fieldEncryptionPlugin, { fields: ['notes', 'description'] });
 */
function fieldEncryptionPlugin(schema, options = {}) {
  const fields = options.fields || [];
  if (!fields.length) return;

  // Pre-save hook: Encrypt fields before storing in MongoDB
  schema.pre('save', function () {
    for (const field of fields) {
      if (this[field] && typeof this[field] === 'string') {
        this[field] = encryptField(this[field]);
      }
    }
  });

  // Post-init hook: Decrypt fields when loaded into document instances
  schema.post('init', function (doc) {
    for (const field of fields) {
      if (doc[field] && typeof doc[field] === 'string') {
        doc[field] = decryptField(doc[field]);
      }
    }
  });
}

module.exports = {
  encryptField,
  decryptField,
  fieldEncryptionPlugin,
};
