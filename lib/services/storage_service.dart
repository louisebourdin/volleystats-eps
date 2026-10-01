import 'package:hive_flutter/hive_flutter.dart';

import '../models/session.dart';

/// Persistance locale des séries (Hive). Le stockage utilise des Map
/// simples (pas de TypeAdapter généré) : les modèles savent se sérialiser
/// eux-mêmes via toJson()/fromJson(), ce qui permettra plus tard de brancher
/// la même logique sur Firebase/Supabase/une API sans toucher aux écrans.
class StorageService {
  static const String _boxName = 'volleystats_sessions';
  static const String _settingsBoxName = 'volleystats_settings';
  static const String _currentClassKey = 'currentClass';
  static const String _pendingUploadsKey = 'pendingUploads';
  static const String _pendingDeletesKey = 'pendingDeletes';
  static const String _migratedKey = 'migratedToRemote';
  static const String _sheetsWebhookUrlKey = 'sheetsWebhookUrl';
  Box? _box;
  Box? _settings;

  /// [testDirectoryPath] permet aux tests d'initialiser Hive sans dépendre du
  /// plugin path_provider (indisponible sous flutter_test).
  Future<void> init({String? testDirectoryPath}) async {
    if (testDirectoryPath != null) {
      Hive.init(testDirectoryPath);
    } else {
      await Hive.initFlutter();
    }
    _box = await Hive.openBox(_boxName);
    _settings = await Hive.openBox(_settingsBoxName);
  }

  Box get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('StorageService.init() doit être appelé avant toute utilisation.');
    }
    return box;
  }

  Box get _requireSettings {
    final box = _settings;
    if (box == null) {
      throw StateError('StorageService.init() doit être appelé avant toute utilisation.');
    }
    return box;
  }

  List<Session> getAllSessions() {
    return _requireBox.values.map((raw) => Session.fromJson(Map<dynamic, dynamic>.from(raw as Map))).toList()
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

  // --- Synchronisation avec l'historique de classe (Supabase) ---

  /// Dernière classe saisie sur cet appareil : l'historique affiche ses séries.
  String? get currentClass => _requireSettings.get(_currentClassKey) as String?;

  Future<void> setCurrentClass(String className) => _requireSettings.put(_currentClassKey, className);

  /// Séries enregistrées ici mais pas encore envoyées (hors ligne, erreur...).
  Set<String> get pendingUploads =>
      ((_requireSettings.get(_pendingUploadsKey) as List?) ?? const []).cast<String>().toSet();

  Future<void> setPendingUploads(Set<String> ids) => _requireSettings.put(_pendingUploadsKey, ids.toList());

  /// Suppressions pas encore répercutées en ligne : {'className': ..., 'id': ...}.
  List<Map<String, String>> get pendingDeletes => ((_requireSettings.get(_pendingDeletesKey) as List?) ?? const [])
      .map((e) => Map<String, String>.from(e as Map))
      .toList();

  Future<void> setPendingDeletes(List<Map<String, String>> deletes) =>
      _requireSettings.put(_pendingDeletesKey, deletes);

  /// Vrai une fois que les séries créées avant l'arrivée de Supabase ont été
  /// mises en file d'envoi.
  bool get migratedToRemote => _requireSettings.get(_migratedKey) as bool? ?? false;

  Future<void> setMigratedToRemote() => _requireSettings.put(_migratedKey, true);

  // --- Export vers Google Sheets ---

  /// URL du Web App Apps Script (voir google_apps_script/Code.gs), configurée
  /// une fois par l'enseignant·e. null/vide = export Google Sheets désactivé.
  String? get sheetsWebhookUrl => _requireSettings.get(_sheetsWebhookUrlKey) as String?;

  Future<void> setSheetsWebhookUrl(String url) => _requireSettings.put(_sheetsWebhookUrlKey, url);
}
