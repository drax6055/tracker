import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

/// Custom symmetric encryption & decryption service for Flutter.
/// Standard: AES-256-CBC with PKCS7 padding, matching backend Node.js crypto.
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;
  static const String _rawSecret = 'ledger_super_secret_32_bytes_key!';

  late final enc.Key _key;
  late final enc.Encrypter _encrypter;

  CryptoService._internal() {
    final keyBytes = crypto.sha256.convert(utf8.encode(_rawSecret)).bytes;
    _key = enc.Key(Uint8List.fromList(keyBytes));
    _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
  }

  /// Encrypt a JSON map, list, or primitive value into an encrypted payload map.
  Map<String, dynamic> encryptPayload(dynamic data) {
    if (data == null) return {};

    final text = data is String ? data : jsonEncode(data);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(text, iv: iv);

    return {
      '_encrypted': true,
      'iv': iv.base64,
      'data': encrypted.base64,
    };
  }

  /// Decrypt an incoming payload map if it contains encrypted fields.
  dynamic decryptPayload(dynamic payload) {
    if (payload == null) return null;
    if (payload is! Map<String, dynamic>) return payload;

    final isEncrypted = payload['_encrypted'] == true;
    final ivBase64 = payload['iv'] as String?;
    final cipherBase64 = payload['data'] as String?;

    if (isEncrypted && ivBase64 != null && cipherBase64 != null) {
      try {
        final iv = enc.IV.fromBase64(ivBase64);
        final encrypted = enc.Encrypted.fromBase64(cipherBase64);
        final decryptedText = _encrypter.decrypt(encrypted, iv: iv);

        try {
          return jsonDecode(decryptedText);
        } catch (_) {
          return decryptedText;
        }
      } catch (e) {
        if (kDebugMode) {
          print('[CryptoService] Decryption failed: $e');
        }
        return payload;
      }
    }

    return payload;
  }
}
