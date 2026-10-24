import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

/// Custom symmetric encryption & decryption service for Flutter.
/// Standard: AES-256-CBC with PKCS7 padding and HMAC-SHA256 authenticated integrity,
/// matching backend Node.js crypto.
class CryptoService {
  static final CryptoService _instance = CryptoService._internal();
  factory CryptoService() => _instance;

  // Key can be injected at build time: --dart-define=PAYLOAD_ENCRYPTION_KEY=your_key
  static const String _envSecret = String.fromEnvironment('PAYLOAD_ENCRYPTION_KEY');
  static const String _fallbackSecret = 'ledger_super_secret_32_bytes_key!';
  static String get _rawSecret => _envSecret.isNotEmpty ? _envSecret : _fallbackSecret;

  late final enc.Key _key;
  late final Uint8List _hmacKeyBytes;
  late final enc.Encrypter _encrypter;

  CryptoService._internal() {
    final keyBytes = crypto.sha256.convert(utf8.encode(_rawSecret)).bytes;
    _key = enc.Key(Uint8List.fromList(keyBytes));
    _hmacKeyBytes = Uint8List.fromList(
      crypto.Hmac(crypto.sha256, keyBytes).convert(utf8.encode('hmac-signature-salt')).bytes,
    );
    _encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
  }

  /// Encrypt a JSON map, list, or primitive value into an encrypted payload map with HMAC.
  Map<String, dynamic> encryptPayload(dynamic data) {
    if (data == null) return {};

    final text = data is String ? data : jsonEncode(data);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(text, iv: iv);

    // Compute HMAC-SHA256 over IV:Ciphertext for integrity authentication
    final hmacDigest = crypto.Hmac(crypto.sha256, _hmacKeyBytes)
        .convert(utf8.encode('${iv.base64}:${encrypted.base64}'));
    final macBase64 = base64Encode(hmacDigest.bytes);

    return {
      '_encrypted': true,
      'iv': iv.base64,
      'data': encrypted.base64,
      'mac': macBase64,
    };
  }

  /// Decrypt an incoming payload map if it contains encrypted fields.
  dynamic decryptPayload(dynamic payload) {
    if (payload == null) return null;
    if (payload is! Map<String, dynamic>) return payload;

    final isEncrypted = payload['_encrypted'] == true;
    final ivBase64 = payload['iv'] as String?;
    final cipherBase64 = payload['data'] as String?;
    final macBase64 = payload['mac'] as String?;

    if (isEncrypted && ivBase64 != null && cipherBase64 != null) {
      try {
        // Verify HMAC if present to prevent tampering and padding oracle attacks
        if (macBase64 != null) {
          final expectedDigest = crypto.Hmac(crypto.sha256, _hmacKeyBytes)
              .convert(utf8.encode('$ivBase64:$cipherBase64'));
          final expectedMac = base64Encode(expectedDigest.bytes);
          if (expectedMac != macBase64) {
            if (kDebugMode) {
              print('[CryptoService] Integrity verification failed: MAC mismatch');
            }
            return payload;
          }
        }

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
