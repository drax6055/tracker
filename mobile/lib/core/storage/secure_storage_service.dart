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

  // Demo User Identification
  static Future<bool> isCurrentUserDemo() async {
    final user = await getUser();
    if (user == null) return false;
    final email = (user['email'] ?? '').toString().toLowerCase().trim();
    return email == 'bruce@wayne.corp' || email == 'bruce@wayn.corp';
  }

  // Demo Datasets (Strictly used for Bruce Wayne demo account only)
  static const List<String> demoCategories = [
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

  static const List<Map<String, dynamic>> demoAccounts = [
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

  static const List<Map<String, dynamic>> demoTransactions = [
    {
      'id': 'tx_1',
      'title': 'Salary Credit',
      'type': 'INCOME',
      'category': 'Salary',
      'account': 'HDFC Salaried Account',
      'date': '14 Oct 2026, 10:30 AM',
      'timestamp': '2026-10-14T10:30:00.000',
      'amount': 125000.0,
      'note': 'Monthly corporate compensation',
    },
    {
      'id': 'tx_2',
      'title': 'Whole Foods Groceries',
      'type': 'EXPENSE',
      'category': 'Food & Dining',
      'account': 'Infinia Metal Card',
      'date': '13 Oct 2026, 8:15 PM',
      'timestamp': '2026-10-13T20:15:00.000',
      'amount': 3450.0,
      'note': 'Weekly supplies & organic groceries',
    },
    {
      'id': 'tx_3',
      'title': 'ATM Cash Withdrawal',
      'type': 'TRANSFER',
      'category': 'Transfer',
      'account': 'HDFC Salaried Account -> Physical Cash Vault',
      'date': '12 Oct 2026, 4:00 PM',
      'timestamp': '2026-10-12T16:00:00.000',
      'amount': 10000.0,
      'note': 'Emergency cash reserve replenishment',
    },
    {
      'id': 'tx_4',
      'title': 'Uber Airport Taxi',
      'type': 'EXPENSE',
      'category': 'Travel & Commute',
      'account': 'Physical Cash Vault',
      'date': '12 Oct 2026, 2:45 PM',
      'timestamp': '2026-10-12T14:45:00.000',
      'amount': 850.0,
      'note': 'Airport commute terminal 2',
    },
    {
      'id': 'tx_5',
      'title': 'Freelance Web Design',
      'type': 'INCOME',
      'category': 'Freelance',
      'account': 'HDFC Salaried Account',
      'date': '11 Oct 2026, 6:30 PM',
      'timestamp': '2026-10-11T18:30:00.000',
      'amount': 45000.0,
      'note': 'Neo-brutalist landing page design project',
    },
    {
      'id': 'tx_6',
      'title': 'Auto Loan Monthly EMI',
      'type': 'EXPENSE',
      'category': 'Bills',
      'account': 'HDFC Salaried Account',
      'date': '10 Oct 2026, 9:00 AM',
      'timestamp': '2026-10-10T09:00:00.000',
      'amount': 14500.0,
      'note': 'Auto debit for vehicle loan',
    },
  ];

  static const List<Map<String, dynamic>> demoDebts = [
    {
      'id': 'debt_1',
      'person': 'Peter Parker',
      'type': 'LENT',
      'originalAmount': 50000.0,
      'remainingAmount': 35000.0,
      'dueDate': '20 Oct 2026',
      'status': 'PARTIALLY_PAID',
      'notes': 'Camera equipment loan',
    },
    {
      'id': 'debt_2',
      'person': 'Tony Stark',
      'type': 'BORROWED',
      'originalAmount': 18000.0,
      'remainingAmount': 18000.0,
      'dueDate': '25 Oct 2026',
      'status': 'PENDING',
      'notes': 'Lab server hosting costs',
    },
    {
      'id': 'debt_3',
      'person': 'Clark Kent',
      'type': 'LENT',
      'originalAmount': 12000.0,
      'remainingAmount': 0.0,
      'dueDate': '01 Oct 2026',
      'status': 'SETTLED',
      'notes': 'Conference ticket',
    },
  ];

  // Categories (Dynamic)
  static const String _categoriesKey = 'ledger_dynamic_categories';

  static Future<void> saveCategories(List<String> categories) async {
    await _storage.write(key: _categoriesKey, value: jsonEncode(categories));
  }

  static Future<List<String>> getCategories() async {
    final str = await _storage.read(key: _categoriesKey);
    if (str != null) {
      try {
        final list = jsonDecode(str) as List<dynamic>;
        return list.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    // If empty and demo user, return demo categories; else completely empty!
    if (await isCurrentUserDemo()) {
      return List<String>.from(demoCategories);
    }
    return [];
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

  static Future<void> saveAccounts(List<Map<String, dynamic>> accounts) async {
    await _storage.write(key: _accountsKey, value: jsonEncode(accounts));
  }

  static Future<List<Map<String, dynamic>>> getAccounts() async {
    final str = await _storage.read(key: _accountsKey);
    if (str != null) {
      try {
        final list = jsonDecode(str) as List<dynamic>;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    // If empty and demo user, return demo accounts; else completely empty!
    if (await isCurrentUserDemo()) {
      return List<Map<String, dynamic>>.from(demoAccounts);
    }
    return [];
  }

  // Transactions (Dynamic)
  static const String _transactionsKey = 'ledger_transactions';

  static Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    await _storage.write(key: _transactionsKey, value: jsonEncode(transactions));
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    final str = await _storage.read(key: _transactionsKey);
    if (str != null) {
      try {
        final list = jsonDecode(str) as List<dynamic>;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    // If empty and demo user, return demo transactions; else completely empty!
    if (await isCurrentUserDemo()) {
      return List<Map<String, dynamic>>.from(demoTransactions);
    }
    return [];
  }

  static Future<void> addTransaction(Map<String, dynamic> tx) async {
    final current = await getTransactions();
    current.insert(0, tx);
    await saveTransactions(current);

    // Adjust account balances dynamically
    final accountName = (tx['account'] ?? '').toString();
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final type = (tx['type'] ?? 'EXPENSE').toString();

    final accounts = await getAccounts();
    if (type == 'TRANSFER' && accountName.contains('->')) {
      final parts = accountName.split('->').map((e) => e.trim()).toList();
      if (parts.length >= 2) {
        for (final acc in accounts) {
          if ((acc['title'] ?? '') == parts[0]) {
            acc['balance'] = ((acc['balance'] as num?)?.toDouble() ?? 0.0) - amount;
          } else if ((acc['title'] ?? '') == parts[1]) {
            acc['balance'] = ((acc['balance'] as num?)?.toDouble() ?? 0.0) + amount;
          }
        }
      }
    } else {
      for (final acc in accounts) {
        if ((acc['title'] ?? '') == accountName) {
          final currentBal = (acc['balance'] as num?)?.toDouble() ?? 0.0;
          if (type == 'EXPENSE') {
            acc['balance'] = currentBal - amount;
          } else if (type == 'INCOME') {
            acc['balance'] = currentBal + amount;
          }
        }
      }
    }
    await saveAccounts(accounts);
  }

  // Debts & Loans (Dynamic)
  static const String _debtsKey = 'ledger_debts';

  static Future<void> saveDebts(List<Map<String, dynamic>> debts) async {
    await _storage.write(key: _debtsKey, value: jsonEncode(debts));
  }

  static Future<List<Map<String, dynamic>>> getDebts() async {
    final str = await _storage.read(key: _debtsKey);
    if (str != null) {
      try {
        final list = jsonDecode(str) as List<dynamic>;
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {}
    }
    // If empty and demo user, return demo debts; else completely empty!
    if (await isCurrentUserDemo()) {
      return List<Map<String, dynamic>>.from(demoDebts);
    }
    return [];
  }

  // Clear All (Logout)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
