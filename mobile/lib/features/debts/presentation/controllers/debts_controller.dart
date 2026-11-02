import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/storage/secure_storage_service.dart';

final debtsProvider =
    NotifierProvider<DebtsNotifier, List<Map<String, dynamic>>>(DebtsNotifier.new);

class DebtsNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    Future.microtask(() => loadDebts());
    return [];
  }

  Future<void> loadDebts() async {
    // 1. Local instant load
    final localList = await SecureStorageService.getDebts();
    state = List<Map<String, dynamic>>.from(localList);

    // 2. Cloud sync
    await CloudSyncService().syncDebts();
    final freshList = await SecureStorageService.getDebts();
    state = List<Map<String, dynamic>>.from(freshList);
  }

  Future<void> addDebt(Map<String, dynamic> debt) async {
    final list = await SecureStorageService.getDebts();
    list.insert(0, debt);
    await SecureStorageService.saveDebts(list);
    await loadDebts();
    unawaited(CloudSyncService().createDebt(debt));
  }

  Future<void> updateDebt(Map<String, dynamic> updated) async {
    final list = await SecureStorageService.getDebts();
    final idx = list.indexWhere((d) => (d['id'] ?? '').toString() == (updated['id'] ?? '').toString());
    if (idx != -1) {
      list[idx] = updated;
      await SecureStorageService.saveDebts(list);
      await loadDebts();
      unawaited(CloudSyncService().syncDebts());
    }
  }

  Future<void> deleteDebt(String id) async {
    final list = await SecureStorageService.getDebts();
    list.removeWhere((d) => (d['id'] ?? '').toString() == id);
    await SecureStorageService.saveDebts(list);
    await loadDebts();
    unawaited(CloudSyncService().deleteDebt(id));
  }

  Future<void> recordPayment(String id, double paidAmount) async {
    final list = await SecureStorageService.getDebts();
    final idx = list.indexWhere((d) => (d['id'] ?? '').toString() == id);
    if (idx != -1) {
      final debt = list[idx];
      final currentRemaining = (debt['remainingAmount'] as num?)?.toDouble() ?? 0.0;
      final newRemaining = (currentRemaining - paidAmount).clamp(0.0, double.infinity);
      debt['remainingAmount'] = newRemaining;
      if (newRemaining == 0.0) {
        debt['status'] = 'SETTLED';
      } else {
        debt['status'] = 'PARTIALLY_PAID';
      }
      list[idx] = debt;
      await SecureStorageService.saveDebts(list);
      await loadDebts();
      unawaited(CloudSyncService().syncDebts());
    }
  }
}
