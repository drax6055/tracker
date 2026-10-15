import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// BankPrivacyService manages OS-level and application-level display protection.
/// Uses Android WindowManager FLAG_SECURE to prevent screenshots, screen recording,
/// and black out / blank the app snapshot in the Recent Apps / App Switcher / App Drawer.
class BankPrivacyService {
  static const MethodChannel _channel = MethodChannel('com.ledger.app/security');

  /// Enable native WindowManager.LayoutParams.FLAG_SECURE
  static Future<bool> enableSecureFlag() async {
    if (kIsWeb) return true;
    try {
      final res = await _channel.invokeMethod<bool>('enableSecureFlag');
      return res ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('[BankPrivacyService] enableSecureFlag warning: $e');
      }
      return false;
    }
  }

  /// Disable native WindowManager.LayoutParams.FLAG_SECURE (e.g. for user preference)
  static Future<bool> disableSecureFlag() async {
    if (kIsWeb) return true;
    try {
      final res = await _channel.invokeMethod<bool>('disableSecureFlag');
      return res ?? true;
    } catch (e) {
      if (kDebugMode) {
        print('[BankPrivacyService] disableSecureFlag warning: $e');
      }
      return false;
    }
  }

  /// Query whether native FLAG_SECURE is active
  static Future<bool> isSecureEnabled() async {
    if (kIsWeb) return true;
    try {
      final res = await _channel.invokeMethod<bool>('isSecureEnabled');
      return res ?? true;
    } catch (e) {
      return true; // Default to secure
    }
  }
}
