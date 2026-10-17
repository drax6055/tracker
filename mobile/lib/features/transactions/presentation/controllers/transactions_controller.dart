import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final list = await SecureStorageService.getTransactions();
    state = List<Map<String, dynamic>>.from(list);
  }

  Future<void> addTransaction(Map<String, dynamic> tx) async {
    await SecureStorageService.addTransaction(tx);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    final current = await SecureStorageService.getTransactions();
    current.removeWhere((t) => (t['id'] ?? '').toString() == id);
    await SecureStorageService.saveTransactions(current);
    await loadTransactions();
  }
}
