import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'ledger_access_token';
  static const String _refreshTokenKey = 'ledger_refresh_token';
  static const String _userKey = 'ledger_user_data';
  static const String _currencyKey = 'ledger_user_currency';

  // Access Token
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Refresh Token
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // User Profile
  static Future<void> saveUser(Map<String, dynamic> userMap) async {
    await _storage.write(key: _userKey, value: jsonEncode(userMap));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final str = await _storage.read(key: _userKey);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // Currency
  static Future<void> saveCurrency(String currency) async {
    await _storage.write(key: _currencyKey, value: currency);
  }

  static Future<String> getCurrency() async {
    return (await _storage.read(key: _currencyKey)) ?? 'INR';
  }

  // Daily Reminder Notification Settings
  static const String _reminderEnabledKey = 'ledger_reminder_enabled';
  static const String _reminderHourKey = 'ledger_reminder_hour';
  static const String _reminderMinuteKey = 'ledger_reminder_minute';

  static Future<void> saveReminderEnabled(bool enabled) async {
    await _storage.write(key: _reminderEnabledKey, value: enabled ? 'true' : 'false');
  }

  static Future<bool> getReminderEnabled() async {
    final val = await _storage.read(key: _reminderEnabledKey);
    return val == null ? true : (val == 'true');
  }

  static Future<void> saveReminderTime(int hour, int minute) async {
    await _storage.write(key: _reminderHourKey, value: hour.toString());
    await _storage.write(key: _reminderMinuteKey, value: minute.toString());
  }

  static Future<Map<String, int>> getReminderTime() async {
    final hourStr = await _storage.read(key: _reminderHourKey);
    final minStr = await _storage.read(key: _reminderMinuteKey);
    final hour = hourStr != null ? int.tryParse(hourStr) ?? 21 : 21; // 9:00 PM default
    final minute = minStr != null ? int.tryParse(minStr) ?? 0 : 0;
    return {'hour': hour, 'minute': minute};
  }

  // Clear All (Logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
