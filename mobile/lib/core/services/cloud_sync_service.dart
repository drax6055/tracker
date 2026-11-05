import 'dart:async';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../network/api_client.dart';
import '../storage/secure_storage_service.dart';
import '../widgets/brutal_toast.dart';

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
        syncNotes(),
        syncIpos(),
      ]);
    } catch (_) {
      // Offline fallback: local cache handles operation smoothly
    }
  }

  /// Sync Accounts between Cloud and Local
  Future<void> syncAccounts() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;
    final isDemo = await SecureStorageService.isCurrentUserDemo();

    try {
      // 1. Fetch from cloud MongoDB (master source of truth)
      final response = await _client.dio.get(ApiEndpoints.accounts);
      final list = response.data['data'] as List<dynamic>?;

      if (list != null) {
        var cloudAccounts = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (!isDemo) {
          // Strictly strip any mock demo accounts for standard accounts
          cloudAccounts = cloudAccounts
              .where((a) => !SecureStorageService.isDemoAccount(a))
              .toList();
        }
        await SecureStorageService.saveAccounts(cloudAccounts);
        return;
      }
    } catch (_) {
      // Offline or network error: keep existing local accounts
    }
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
    } catch (e) {
      debugPrint('[CloudSync] Error updating cloud account $id: $e');
      BrutalToast.showError(null, 'ERROR UPDATING CLOUD ACCOUNT: $e');
    }
  }

  /// Delete Account in Cloud
  Future<void> deleteAccount(String id) async {
    try {
      await _client.dio.delete('${ApiEndpoints.accounts}/$id');
    } catch (e) {
      debugPrint('[CloudSync] Error deleting cloud account $id: $e');
      BrutalToast.showError(null, 'ERROR DELETING CLOUD ACCOUNT: $e');
    }
  }

  /// Sync Transactions between Cloud and Local
  Future<void> syncTransactions() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;
    final isDemo = await SecureStorageService.isCurrentUserDemo();

    try {
      // 1. Fetch from cloud MongoDB (master source of truth)
      final response = await _client.dio.get(ApiEndpoints.transactions);
      final list = response.data['data'] as List<dynamic>?;

      if (list != null) {
        var cloudTxs = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (!isDemo) {
          cloudTxs = cloudTxs
              .where((t) => !SecureStorageService.isDemoTransaction(t))
              .toList();
        }
        await SecureStorageService.saveTransactions(cloudTxs);
        return;
      }
    } catch (_) {
      // Offline or network error
    }
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
    } catch (e) {
      debugPrint('[CloudSync] Error deleting cloud transaction $id: $e');
      BrutalToast.showError(null, 'ERROR DELETING CLOUD TRANSACTION: $e');
    }
  }

  /// Sync Categories
  Future<void> syncCategories() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await _client.dio.get(ApiEndpoints.categories);
      final list = response.data['data'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        final cloudCats = list.map((e) => (e is Map ? e['name'] : e).toString()).toList();
        await SecureStorageService.saveCategories(cloudCats);
      }
    } catch (e) {
      debugPrint('[CloudSync] Error syncing categories: $e');
      BrutalToast.showError(null, 'ERROR SYNCING CATEGORIES: $e');
    }

  }

  /// Sync Debts
  Future<void> syncDebts() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;
    final isDemo = await SecureStorageService.isCurrentUserDemo();

    try {
      // 1. Fetch from cloud MongoDB (master source of truth)
      final response = await _client.dio.get(ApiEndpoints.debts);
      final list = response.data['data'] as List<dynamic>?;

      if (list != null) {
        var cloudDebts = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (!isDemo) {
          cloudDebts = cloudDebts
              .where((d) => !SecureStorageService.isDemoDebt(d))
              .toList();
        }
        await SecureStorageService.saveDebts(cloudDebts);
        return;
      }
    } catch (_) {
      // Offline or network error
    }
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
    } catch (e) {
      debugPrint('[CloudSync] Error deleting cloud debt $id: $e');
      BrutalToast.showError(null, 'ERROR DELETING CLOUD DEBT: $e');
    }
  }

  /// Sync Sticky Notes between Cloud and Local
  Future<void> syncNotes() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await _client.dio.get(ApiEndpoints.notes);
      final list = response.data['data'] as List<dynamic>?;

      if (list != null) {
        final cloudNotes = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        await SecureStorageService.saveNotes(cloudNotes);
        return;
      }
    } catch (_) {
      // Offline fallback
    }
  }

  /// Create Note in Cloud
  Future<Map<String, dynamic>?> createNote(Map<String, dynamic> noteData) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.notes,
        data: noteData,
      );
      return response.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Update Note in Cloud
  Future<void> updateNote(String id, Map<String, dynamic> noteData) async {
    try {
      await _client.dio.put(
        '${ApiEndpoints.notes}/$id',
        data: noteData,
      );
    } catch (e) {
      debugPrint('[CloudSync] Error updating cloud note $id: $e');
      BrutalToast.showError(null, 'ERROR UPDATING CLOUD NOTE: $e');
    }
  }

  /// Delete Note in Cloud
  Future<void> deleteNote(String id) async {
    try {
      await _client.dio.delete('${ApiEndpoints.notes}/$id');
    } catch (e) {
      debugPrint('[CloudSync] Error deleting cloud note $id: $e');
      BrutalToast.showError(null, 'ERROR DELETING CLOUD NOTE: $e');
    }
  }

  /// Sync IPO Applications between Cloud and Local
  Future<void> syncIpos() async {
    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final response = await _client.dio.get(ApiEndpoints.ipos);
      final list = response.data['data'] as List<dynamic>?;

      if (list != null) {
        final cloudIpos = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        await SecureStorageService.saveIpos(cloudIpos);
        return;
      }
    } catch (_) {
      // Offline fallback
    }
  }

  /// Create IPO Application in Cloud
  Future<Map<String, dynamic>?> createIpo(Map<String, dynamic> ipoData) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.ipos,
        data: ipoData,
      );
      return response.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Update IPO Application in Cloud
  Future<void> updateIpo(String id, Map<String, dynamic> ipoData) async {
    try {
      await _client.dio.put(
        '${ApiEndpoints.ipos}/$id',
        data: ipoData,
      );
    } catch (e) {
      debugPrint('[CloudSync] Error updating cloud IPO $id: $e');
      BrutalToast.showError(null, 'ERROR UPDATING CLOUD IPO: $e');
    }
  }

  /// Delete IPO Application in Cloud
  Future<void> deleteIpo(String id) async {
    try {
      await _client.dio.delete('${ApiEndpoints.ipos}/$id');
    } catch (e) {
      debugPrint('[CloudSync] Error deleting cloud IPO $id: $e');
      BrutalToast.showError(null, 'ERROR DELETING CLOUD IPO: $e');
    }
  }

  /// Get CA Tax Audit Report from Cloud
  Future<Map<String, dynamic>?> fetchCaReport({String? fy, String? applicant, String? pan}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (fy != null && fy.isNotEmpty) queryParams['fy'] = fy;
      if (applicant != null && applicant.isNotEmpty) queryParams['applicant'] = applicant;
      if (pan != null && pan.isNotEmpty) queryParams['pan'] = pan;

      final response = await _client.dio.get(
        ApiEndpoints.ipoCaReport,
        queryParameters: queryParams,
      );
      return response.data['data'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
