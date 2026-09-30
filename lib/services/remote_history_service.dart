import 'package:supabase/supabase.dart' show SupabaseClient;

import '../config/supabase_config.dart';
import '../models/session.dart';

/// Historique partagé d'une classe, stocké dans Supabase. Passe uniquement par
/// les fonctions SQL de supabase/schema.sql (pas d'accès direct à la table).
class RemoteHistoryService {
  final SupabaseClient _client;

  RemoteHistoryService(this._client);

  /// null si l'URL/la clé Supabase ne sont pas renseignées.
  static RemoteHistoryService? fromConfig() {
    if (!SupabaseConfig.isConfigured) return null;
    return RemoteHistoryService(SupabaseClient(SupabaseConfig.url, SupabaseConfig.anonKey));
  }

  Future<List<Session>> fetchClassSessions(String className) async {
    final rows = await _client.rpc('get_class_sessions', params: {'p_class': className}) as List;
    return rows.map((raw) => Session.fromJson(Map<dynamic, dynamic>.from(raw as Map))).toList();
  }

  Future<void> upsertSession(Session session) async {
    await _client.rpc('upsert_session', params: {'p_session': session.toJson()});
  }

  Future<void> deleteSession({required String className, required String id}) async {
    await _client.rpc('delete_session', params: {'p_class': className, 'p_id': id});
  }
}
