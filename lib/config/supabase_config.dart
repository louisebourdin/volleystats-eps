/// Connexion au projet Supabase qui stocke l'historique partagé par classe.
///
/// Les valeurs se trouvent dans Supabase : Project Settings > API
/// (« Project URL » et clé « anon » / « publishable »). Cette clé est publique
/// par conception : la base n'expose que les fonctions de supabase/schema.sql.
///
/// On peut aussi les passer au build sans modifier ce fichier :
///   flutter build web --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// Tant qu'elles sont vides, l'appli fonctionne comme avant (historique local
/// uniquement).
class SupabaseConfig {
  static const String url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://ugduqwhfabtmmhnbvcdx.supabase.co');
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_aaVJ2LPwXJZ0kKytEgaPJg_UCYK5Tim',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
