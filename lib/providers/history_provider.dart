import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';

class HistoryNotifier extends StateNotifier<List<Session>> {
  final StorageService _storage;

  HistoryNotifier(this._storage) : super(_storage.getAllSessions());

  void _sort() {
    state = [...state]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addOrUpdate(Session session) async {
    await _storage.saveSession(session);
    final idx = state.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      final copy = [...state];
      copy[idx] = session;
      state = copy;
    } else {
      state = [...state, session];
    }
    _sort();
  }

  Future<void> remove(String id) async {
    await _storage.deleteSession(id);
    state = state.where((s) => s.id != id).toList();
  }

  void refresh() {
    state = _storage.getAllSessions();
  }

  /// Toutes les séries d'un même élève (même prénom/pseudo), triées par date
  /// croissante — utilisé pour la comparaison de progression (§19).
  List<Session> sessionsForStudent(String studentName) {
    final list = state.where((s) => s.student.name.toLowerCase() == studentName.toLowerCase()).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }
}

final historyProvider = StateNotifierProvider<HistoryNotifier, List<Session>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return HistoryNotifier(storage);
});
