import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:volleystats_eps/models/serve_enums.dart';
import 'package:volleystats_eps/models/session.dart';
import 'package:volleystats_eps/models/student.dart';
import 'package:volleystats_eps/providers/history_provider.dart';
import 'package:volleystats_eps/providers/storage_provider.dart';
import 'package:volleystats_eps/services/remote_history_service.dart';
import 'package:volleystats_eps/services/storage_service.dart';

/// Base Supabase simulée en mémoire ; [online] = false simule une coupure réseau.
class FakeRemote implements RemoteHistoryService {
  final Map<String, Session> rows = {};
  bool online = true;

  void _check() {
    if (!online) throw const SocketException('hors ligne');
  }

  @override
  Future<List<Session>> fetchClassSessions(String className) async {
    _check();
    return rows.values.where((s) => classKey(s.student.className) == classKey(className)).toList();
  }

  @override
  Future<void> upsertSession(Session session) async {
    _check();
    rows[session.id] = session;
  }

  @override
  Future<void> deleteSession({required String className, required String id}) async {
    _check();
    rows.remove(id);
  }
}

Session _session(String id, String className) => Session(
      id: id,
      student: Student(name: 'Élève $id', className: className, dominantHand: DominantHand.droitier, mainServeTypeId: 'tennis'),
      date: DateTime(2026, 9, 30),
    );

void main() {
  late Directory dir;
  late StorageService storage;
  late FakeRemote remote;
  late ProviderContainer container;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('volleystats_test');
    storage = StorageService();
    await storage.init(testDirectoryPath: dir.path);
    remote = FakeRemote();
    container = ProviderContainer(overrides: [
      storageServiceProvider.overrideWithValue(storage),
      remoteHistoryServiceProvider.overrideWithValue(remote),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  HistoryNotifier notifier() => container.read(historyProvider.notifier);

  test('une série terminée est envoyée et devient la classe courante', () async {
    await notifier().addOrUpdate(_session('a', '2e1'));
    await notifier().sync();

    expect(remote.rows.keys, ['a']);
    expect(container.read(currentClassProvider), '2e1');
    expect(container.read(syncStatusProvider), SyncStatus.synced);
  });

  test("hors ligne, la série reste en attente puis part au retour du réseau", () async {
    remote.online = false;
    await notifier().addOrUpdate(_session('a', '2e1'));
    await notifier().sync();
    expect(remote.rows, isEmpty);
    expect(container.read(syncStatusProvider), SyncStatus.offline);
    expect(container.read(historyProvider).map((s) => s.id), ['a']);

    remote.online = true;
    await notifier().sync();
    expect(remote.rows.keys, ['a']);
  });

  test("récupère les séries de la classe enregistrées depuis un autre appareil", () async {
    remote.rows['b'] = _session('b', '2e1');
    remote.rows['c'] = _session('c', '2e2');
    await notifier().setCurrentClass('2e1');

    expect(container.read(historyProvider).map((s) => s.id), ['b']);
  });

  test("une série supprimée depuis un autre appareil disparaît", () async {
    await notifier().addOrUpdate(_session('a', '2e1'));
    await notifier().sync();
    remote.rows.remove('a');

    await notifier().sync();
    expect(container.read(historyProvider), isEmpty);
  });

  test('une suppression hors ligne est répercutée au retour du réseau', () async {
    await notifier().addOrUpdate(_session('a', '2e1'));
    await notifier().sync();

    remote.online = false;
    await notifier().remove('a');
    await notifier().sync();
    expect(remote.rows.keys, ['a']);

    remote.online = true;
    await notifier().sync();
    expect(remote.rows, isEmpty);
    expect(container.read(historyProvider), isEmpty);
  });
}
