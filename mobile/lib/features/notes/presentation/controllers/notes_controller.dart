import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/cloud_sync_service.dart';
import '../../../../core/storage/secure_storage_service.dart';

final notesProvider =
    NotifierProvider<NotesNotifier, List<Map<String, dynamic>>>(NotesNotifier.new);

class NotesNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    Future.microtask(() => loadNotes());
    return [];
  }

  Future<void> loadNotes() async {
    // 1. Instant local read
    final localNotes = await SecureStorageService.getNotes();
    state = List<Map<String, dynamic>>.from(localNotes);

    // 2. Background sync with cloud
    await CloudSyncService().syncNotes();
    final freshNotes = await SecureStorageService.getNotes();
    state = List<Map<String, dynamic>>.from(freshNotes);
  }

  Future<void> addNote(Map<String, dynamic> note) async {
    await SecureStorageService.addNote(note);
    await loadNotes();
    unawaited(CloudSyncService().createNote(note));
  }

  Future<void> updateNote(Map<String, dynamic> note) async {
    await SecureStorageService.updateNote(note);
    await loadNotes();
    final id = (note['id'] ?? note['_id'] ?? '').toString();
    if (id.isNotEmpty && id.length == 24) {
      unawaited(CloudSyncService().updateNote(id, note));
    } else {
      unawaited(CloudSyncService().createNote(note));
    }
  }

  Future<void> deleteNote(String id) async {
    await SecureStorageService.deleteNote(id);
    await loadNotes();
    if (id.length == 24) {
      unawaited(CloudSyncService().deleteNote(id));
    }
  }

  Future<void> togglePin(String id) async {
    await SecureStorageService.togglePinNote(id);
    await loadNotes();
    final note = state.firstWhere(
      (n) => (n['id'] ?? n['_id'] ?? '').toString() == id,
      orElse: () => {},
    );
    if (note.isNotEmpty && id.length == 24) {
      unawaited(CloudSyncService().updateNote(id, {'isPinned': note['isPinned']}));
    }
  }
}
