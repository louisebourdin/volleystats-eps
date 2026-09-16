import 'package:hive_flutter/hive_flutter.dart';

import '../models/session.dart';

/// Persistance locale des séries (Hive). Le stockage utilise des Map
/// simples (pas de TypeAdapter généré) : les modèles savent se sérialiser
/// eux-mêmes via toJson()/fromJson(), ce qui permettra plus tard de brancher
/// la même logique sur Firebase/Supabase/une API sans toucher aux écrans.
class StorageService {
  static const String _boxName = 'volleystats_sessions';
  Box? _box;

  /// [testDirectoryPath] permet aux tests d'initialiser Hive sans dépendre du
  /// plugin path_provider (indisponible sous flutter_test).
  Future<void> init({String? testDirectoryPath}) async {
    if (testDirectoryPath != null) {
      Hive.init(testDirectoryPath);
    } else {
      await Hive.initFlutter();
    }
    _box = await Hive.openBox(_boxName);
  }

  Box get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('StorageService.init() doit être appelé avant toute utilisation.');
    }
    return box;
  }

  List<Session> getAllSessions() {
    return _requireBox.values
        .map((raw) => Session.fromJson(Map<dynamic, dynamic>.from(raw as Map)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> saveSession(Session session) async {
    await _requireBox.put(session.id, session.toJson());
  }

  Future<void> deleteSession(String id) async {
    await _requireBox.delete(id);
  }

  Future<void> clearAll() async {
    await _requireBox.clear();
  }
}
