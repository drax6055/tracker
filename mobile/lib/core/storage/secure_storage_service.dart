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

  // Categories (Dynamic)
  static const String _categoriesKey = 'ledger_dynamic_categories';
  static const List<String> defaultCategories = [
    'Food & Dining',
    'Rent & Utilities',
    'Travel & Commute',
    'Shopping',
    'Health & Medical',
    'Entertainment',
    'Salary',
    'Freelance',
    'Investment',
    'Bills',
  ];

  static Future<void> saveCategories(List<String> categories) async {
    await _storage.write(key: _categoriesKey, value: jsonEncode(categories));
  }

  static Future<List<String>> getCategories() async {
    final str = await _storage.read(key: _categoriesKey);
    if (str == null) return List<String>.from(defaultCategories);
    try {
      final list = jsonDecode(str) as List<dynamic>;
      final result = list.map((e) => e.toString()).toList();
      return result.isEmpty ? List<String>.from(defaultCategories) : result;
    } catch (_) {
      return List<String>.from(defaultCategories);
    }
  }

  // Custom Categories (Legacy compatibility)
  static const String _customCategoriesKey = 'ledger_custom_categories';

  static Future<void> saveCustomCategories(List<String> categories) async {
    await _storage.write(key: _customCategoriesKey, value: jsonEncode(categories));
  }

  static Future<List<String>> getCustomCategories() async {
    return await getCategories();
  }

  // Accounts Vault (Dynamic)
  static const String _accountsKey = 'ledger_vault_accounts';
  static const List<Map<String, dynamic>> defaultAccounts = [
    {
      'id': 'acc_1',
      'title': 'HDFC Salaried Account',
      'subtitle': 'HDFC Bank • Last 4: 4821',
      'balance': 425000.0,
      'type': 'BANK',
      'digits': '4821',
    },
    {
      'id': 'acc_2',
      'title': 'Physical Cash Vault',
      'subtitle': 'Safe Box & Pocket Wallet',
      'balance': 24500.0,
      'type': 'CASH',
      'digits': 'WAL',
    },
    {
      'id': 'acc_3',
      'title': 'Infinia Metal Card',
      'subtitle': 'HDFC Bank • Limit: ₹5,00,000',
      'balance': 48500.0,
      'type': 'CREDIT_CARD',
      'digits': '9920',
      'subtext': 'UTILIZATION: 9.7% • DUE 22ND OF MONTH',
    },
    {
      'id': 'acc_4',
      'title': 'Vehicle Loan #49281',
      'subtitle': 'Principal: ₹5,00,000 @ 8.4% • 36 Months',
      'balance': 356300.0,
      'type': 'LOAN',
      'digits': 'SBI',
      'subtext': 'REMAINING: 28% • EMI ₹14,500',
    },
  ];

  static Future<void> saveAccounts(List<Map<String, dynamic>> accounts) async {
    await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
  }

  static Future<List<Map<String, dynamic>>> getAccounts() async {
    final str = await _storage.read(key: _accountsKey);
    if (str == null) return List<Map<String, dynamic>>.from(defaultAccounts);
    try {
      final list = jsonDecode(str) as List<dynamic>;
      final result = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      return result.isEmpty ? List<Map<String, dynamic>>.from(defaultAccounts) : result;
    } catch (_) {
      return List<Map<String, dynamic>>.from(defaultAccounts);
    }
  }

  // Clear All (Logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
