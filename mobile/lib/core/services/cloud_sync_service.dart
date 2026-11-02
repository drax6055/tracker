
import 'dart:async';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  final _client = ApiClient();

  /// Sync all modules (Accounts, Transactions, Categories, Debts) with MongoDB Cloud
  Future<void> syncAll() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      await Future.wait([
        syncAccounts(),
        syncTransactions(),
        syncCategories(),
        syncDebts(),
      ]);
    } catch (_) {
      // Offline fallback: local cache handles operation smoothly
    }
  }

  /// Sync Accounts between Cloud and Local
  Future<void> syncAccounts() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final local = await SecureStorageService.getAccounts();
      if (local.isNotEmpty) {
        final postRes = await _client.dio.post(
          '${ApiEndpoints.accounts}/sync',
          data: {'accounts': local},
        );
        final list = postRes.data['data'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final cloudAccounts = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          await SecureStorageService.saveAccounts(cloudAccounts);
          return;
        }
      }

      final response = await _client.dio.get(ApiEndpoints.accounts);
      final list = response.data['data'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        final cloudAccounts = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        await SecureStorageService.saveAccounts(cloudAccounts);
      }
    } catch (_) {}
  }

  /// Create Account in Cloud
  Future<Map<String, dynamic>?> createAccount(Map<String, dynamic> accountData) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.accounts,
        data: accountData,
      );
      return response.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Update Account in Cloud
  Future<void> updateAccount(String id, Map<String, dynamic> accountData) async {
    try {
      await _client.dio.put(
        '${ApiEndpoints.accounts}/$id',
        data: accountData,
      );
    } catch (_) {}
  }

  /// Delete Account in Cloud
  Future<void> deleteAccount(String id) async {
    try {
      await _client.dio.delete('${ApiEndpoints.accounts}/$id');
    } catch (_) {}
  }

  /// Sync Transactions between Cloud and Local
  Future<void> syncTransactions() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final local = await SecureStorageService.getTransactions();
      if (local.isNotEmpty) {
        final postRes = await _client.dio.post(
          '${ApiEndpoints.transactions}/sync',
          data: {'transactions': local},
        );
        final list = postRes.data['data'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final cloudTxs = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          await SecureStorageService.saveTransactions(cloudTxs);
          return;
        }
      }

      final response = await _client.dio.get(ApiEndpoints.transactions);
      final list = response.data['data'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        final cloudTxs = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        await SecureStorageService.saveTransactions(cloudTxs);
      }
    } catch (_) {}
  }

  /// Create Transaction in Cloud
  Future<Map<String, dynamic>?> createTransaction(Map<String, dynamic> txData) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.transactions,
        data: txData,
      );
      return response.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Delete Transaction in Cloud
  Future<void> deleteTransaction(String id) async {
    try {
      await _client.dio.delete('${ApiEndpoints.transactions}/$id');
    } catch (_) {}
  }

  /// Sync Categories
  Future<void> syncCategories() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final local = await SecureStorageService.getCategories();
      if (local.isNotEmpty) {
        final postRes = await _client.dio.post(
          '${ApiEndpoints.categories}/sync',
          data: {'categories': local},
        );
        final list = postRes.data['data'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final cloudCats = list.map((e) => (e is Map ? e['name'] : e).toString()).toList();
          await SecureStorageService.saveCategories(cloudCats);
          return;
        }
      }

      final response = await _client.dio.get(ApiEndpoints.categories);
      final list = response.data['data'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        final cloudCats = list.map((e) => (e is Map ? e['name'] : e).toString()).toList();
        await SecureStorageService.saveCategories(cloudCats);
      }
    } catch (_) {}
  }

  /// Sync Debts
  Future<void> syncDebts() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final local = await SecureStorageService.getDebts();
      if (local.isNotEmpty) {
        final postRes = await _client.dio.post(
          '${ApiEndpoints.debts}/sync',
          data: {'debts': local},
        );
        final list = postRes.data['data'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final cloudDebts = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          await SecureStorageService.saveDebts(cloudDebts);
          return;
        }
      }

      final response = await _client.dio.get(ApiEndpoints.debts);
      final list = response.data['data'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        final cloudDebts = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        await SecureStorageService.saveDebts(cloudDebts);
      }
    } catch (_) {}
  }

  /// Create Debt in Cloud
  Future<Map<String, dynamic>?> createDebt(Map<String, dynamic> debtData) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.debts,
        data: debtData,
      );
      return response.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Delete Debt in Cloud
  Future<void> deleteDebt(String id) async {
    try {
      await _client.dio.delete('${ApiEndpoints.debts}/$id');
    } catch (_) {}
  }
}
