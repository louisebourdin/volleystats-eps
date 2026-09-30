import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import '../services/demo_data_service.dart';
import '../services/remote_history_service.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';

/// État de la synchronisation avec l'historique de classe en ligne.
enum SyncStatus { disabled, syncing, synced, offline }

/// Même normalisation que public.class_key() côté Supabase : « 2nde 4 »,
/// « 2NDE  4 » et « 2nde 4 » désignent la même classe.
String classKey(String className) => className.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// null si Supabase n'est pas configuré (historique local uniquement).
final remoteHistoryServiceProvider = Provider<RemoteHistoryService?>((ref) => RemoteHistoryService.fromConfig());

final syncStatusProvider = StateProvider<SyncStatus>(
  (ref) => ref.watch(remoteHistoryServiceProvider) == null ? SyncStatus.disabled : SyncStatus.syncing,
);

/// Classe dont l'historique est affiché : la dernière saisie sur cet appareil.
final currentClassProvider = StateProvider<String?>((ref) => ref.watch(storageServiceProvider).currentClass);

class HistoryNotifier extends StateNotifier<List<Session>> {
  final Ref _ref;
  final StorageService _storage;
  final RemoteHistoryService? _remote;

  Future<void>? _running;
  bool _rerun = false;

  HistoryNotifier(this._ref, this._storage, this._remote) : super(_storage.getAllSessions()) {
    if (_remote != null) {
      Future.microtask(() async {
        await _queueLegacySessions();
        await sync();
      });
    }
  }

  static bool _isShared(Session s) => !DemoDataService.isDemo(s) && classKey(s.student.className).isNotEmpty;

  void _sort() {
    state = [...state]..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Les séries enregistrées avant l'arrivée de Supabase partent en ligne au
  /// premier lancement.
  Future<void> _queueLegacySessions() async {
    if (_storage.migratedToRemote) return;
    await _storage.setPendingUploads({..._storage.pendingUploads, ...state.where(_isShared).map((s) => s.id)});
    await _storage.setMigratedToRemote();
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

    if (_isShared(session)) {
      await setCurrentClass(session.student.className, syncNow: false);
      if (_remote != null) {
        await _storage.setPendingUploads({..._storage.pendingUploads, session.id});
        unawaited(sync());
      }
    }
  }

  Future<void> remove(String id) async {
    final removed = state.where((s) => s.id == id).firstOrNull;
    await _storage.deleteSession(id);
    state = state.where((s) => s.id != id).toList();

    if (_remote != null && removed != null && _isShared(removed)) {
      await _storage.setPendingUploads(_storage.pendingUploads..remove(id));
      await _storage.setPendingDeletes([
        ..._storage.pendingDeletes,
        {'className': removed.student.className, 'id': id},
      ]);
      unawaited(sync());
    }
  }

  Future<void> setCurrentClass(String className, {bool syncNow = true}) async {
    final name = className.trim();
    if (name.isEmpty) return;
    await _storage.setCurrentClass(name);
    _ref.read(currentClassProvider.notifier).state = name;
    if (syncNow) await sync();
  }

  void refresh() {
    state = _storage.getAllSessions();
  }

  /// Envoie les modifications en attente puis récupère l'historique de la
  /// classe courante. Sans réseau, tout reste en file et repartira au prochain
  /// appel.
  Future<void> sync() async {
    if (_remote == null) return;
    if (_running != null) {
      _rerun = true;
      return _running;
    }
    _running = _syncLoop();
    try {
      await _running;
    } finally {
      _running = null;
    }
  }

  Future<void> _syncLoop() async {
    do {
      _rerun = false;
      await _syncOnce();
    } while (_rerun && mounted);
  }

  Future<void> _syncOnce() async {
    final remote = _remote!;
    _setStatus(SyncStatus.syncing);
    try {
      for (final del in _storage.pendingDeletes) {
        await remote.deleteSession(className: del['className']!, id: del['id']!);
        await _storage.setPendingDeletes(_storage.pendingDeletes..removeWhere((d) => d['id'] == del['id']));
      }

      for (final id in _storage.pendingUploads) {
        final session = state.where((s) => s.id == id).firstOrNull;
        if (session != null) await remote.upsertSession(session);
        await _storage.setPendingUploads(_storage.pendingUploads..remove(id));
      }

      final currentClass = _storage.currentClass;
      if (currentClass != null) {
        final key = classKey(currentClass);
        final remoteSessions = await remote.fetchClassSessions(currentClass);
        final remoteIds = remoteSessions.map((s) => s.id).toSet();
        final pending = _storage.pendingUploads;
        final deleted = _storage.pendingDeletes.map((d) => d['id']).toSet();

        // Séries supprimées depuis un autre appareil.
        for (final s in state) {
          if (_isShared(s) &&
              classKey(s.student.className) == key &&
              !remoteIds.contains(s.id) &&
              !pending.contains(s.id)) {
            await _storage.deleteSession(s.id);
          }
        }
        for (final s in remoteSessions) {
          if (!deleted.contains(s.id) && !pending.contains(s.id)) await _storage.saveSession(s);
        }
        if (mounted) refresh();
      }
      _setStatus(SyncStatus.synced);
    } catch (_) {
      _setStatus(SyncStatus.offline);
    }
  }

  void _setStatus(SyncStatus status) {
    if (mounted) _ref.read(syncStatusProvider.notifier).state = status;
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
  return HistoryNotifier(ref, storage, ref.watch(remoteHistoryServiceProvider));
});
