import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/storage/secure_storage_service.dart';

final transactionsProvider =
    NotifierProvider<TransactionsNotifier, List<Map<String, dynamic>>>(TransactionsNotifier.new);

class TransactionsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    Future.microtask(() => loadTransactions());
    return [];
  }

  Future<void> loadTransactions() async {
    // 1. Instant load from local storage
    final localList = await SecureStorageService.getTransactions();
    state = List<Map<String, dynamic>>.from(localList);

    // 2. Background sync with cloud
    await CloudSyncService().syncTransactions();
    final freshList = await SecureStorageService.getTransactions();
    state = List<Map<String, dynamic>>.from(freshList);
  }

  Future<void> addTransaction(Map<String, dynamic> tx) async {
    await SecureStorageService.addTransaction(tx);
    await loadTransactions();
    unawaited(CloudSyncService().createTransaction(tx));
  }

  Future<void> updateTransaction(Map<String, dynamic> tx) async {
    await SecureStorageService.updateTransaction(tx);
    await loadTransactions();
    unawaited(CloudSyncService().syncTransactions());
  }

  Future<void> deleteTransaction(String id) async {
    final current = await SecureStorageService.getTransactions();
    current.removeWhere((t) => (t['id'] ?? '').toString() == id);
    await SecureStorageService.saveTransactions(current);
    await loadTransactions();
    unawaited(CloudSyncService().deleteTransaction(id));
  }
}
