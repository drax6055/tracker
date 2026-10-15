import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/core/security/crypto_service.dart';

void main() {
  test('CryptoService Encrypt and Decrypt Round-Trip Test', () {
    final crypto = CryptoService();
    final originalData = {
      'accountId': 'acc_98765',
      'amount': 250000,
      'currency': 'INR',
      'notes': 'End-to-End Encrypted Wire'
    };

    final encrypted = crypto.encryptPayload(originalData);
    expect(encrypted['_encrypted'], true);
    expect(encrypted['iv'], isNotNull);
    expect(encrypted['data'], isNotNull);

    final decrypted = crypto.decryptPayload(encrypted);
    expect(decrypted, originalData);
  });

  test('Cross-Platform Compatibility: Dart decrypts Node.js payload', () {
    final crypto = CryptoService();
    final nodePayload = {
      '_encrypted': true,
      'iv': 'HxyhTil1+kPRr7g+G2xzwg==',
      'data': 'hwDWiSyxEFXZToTXb+66Izz+73lhgMnR9LVaQ9cJPcDTpYuVFlrH7BYCUKvMHp5nW1ZHKw2LuHyQfW44ftMFwQ=='
    };

    final result = crypto.decryptPayload(nodePayload);
    expect(result, isA<Map<String, dynamic>>());
    expect(result['user'], 'Dhairy');
    expect(result['amount'], 50000);
    expect(result['action'], 'TRANSFER');
  });
}
