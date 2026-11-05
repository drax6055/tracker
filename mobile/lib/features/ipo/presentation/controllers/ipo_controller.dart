import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/storage/secure_storage_service.dart';

final ipoProvider =
    NotifierProvider<IpoNotifier, List<Map<String, dynamic>>>(IpoNotifier.new);

class IpoNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    Future.microtask(() => loadIpos());
    return [];
  }

  Future<void> loadIpos() async {
    // 1. Instant local read
    final local = await SecureStorageService.getIpos();
    state = List<Map<String, dynamic>>.from(local);

    // 2. Background sync with cloud
    await CloudSyncService().syncIpos();
    final fresh = await SecureStorageService.getIpos();
    state = List<Map<String, dynamic>>.from(fresh);
  }

  Future<void> addIpo(Map<String, dynamic> ipo) async {
    await SecureStorageService.addIpo(ipo);
    await loadIpos();
    unawaited(CloudSyncService().createIpo(ipo));
  }

  Future<void> updateIpo(Map<String, dynamic> ipo) async {
    await SecureStorageService.updateIpo(ipo);
    await loadIpos();
    final id = (ipo['id'] ?? ipo['_id'] ?? '').toString();
    if (id.isNotEmpty && id.length == 24) {
      unawaited(CloudSyncService().updateIpo(id, ipo));
    } else {
      unawaited(CloudSyncService().createIpo(ipo));
    }
  }

  Future<void> deleteIpo(String id) async {
    await SecureStorageService.deleteIpo(id);
    await loadIpos();
    if (id.length == 24) {
      unawaited(CloudSyncService().deleteIpo(id));
    }
  }

  Future<void> recordExit(
    String id, {
    required double exitPrice,
    required int exitShares,
    required String exitDate,
  }) async {
    final current = state.firstWhere(
      (i) => (i['id'] ?? i['_id'] ?? '').toString() == id,
      orElse: () => {},
    );
    if (current.isEmpty) return;

    final bidPrice = (current['bidPrice'] as num?)?.toDouble() ?? 0.0;
    final grossProceeds = exitPrice * exitShares;
    const dpCharges = 15.93;
    final sttCharges = (grossProceeds * 0.001).roundToDouble();
    final buyCost = exitShares * bidPrice;
    final netGain = grossProceeds - buyCost - dpCharges - sttCharges;

    String gainType = 'STCG';
    final allotDateStr = current['allotmentDate'] ?? current['createdAt'];
    if (allotDateStr != null && allotDateStr.toString().isNotEmpty) {
      final d1 = DateTime.tryParse(allotDateStr.toString());
      final d2 = DateTime.tryParse(exitDate);
      if (d1 != null && d2 != null && d2.difference(d1).inDays > 365) {
        gainType = 'LTCG';
      }
    }

    // Determine Financial Year
    final exitDt = DateTime.tryParse(exitDate) ?? DateTime.now();
    final fy = exitDt.month >= 4
        ? '${exitDt.year}-${exitDt.year + 1}'
        : '${exitDt.year - 1}-${exitDt.year}';

    final updated = Map<String, dynamic>.from(current);
    updated['status'] = 'EXITED';
    updated['exitPrice'] = exitPrice;
    updated['exitShares'] = exitShares;
    updated['exitDate'] = exitDate;
    updated['grossProceeds'] = grossProceeds;
    updated['dpCharges'] = dpCharges;
    updated['sttCharges'] = sttCharges;
    updated['netGain'] = netGain;
    updated['gainType'] = gainType;
    updated['financialYear'] = fy;
    updated['updatedAt'] = DateTime.now().toIso8601String();

    await updateIpo(updated);
  }
}

