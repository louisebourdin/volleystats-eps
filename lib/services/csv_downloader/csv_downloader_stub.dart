/// Ne devrait jamais être utilisée : toute plateforme cible de l'application
/// (web, Android, iOS, Windows, macOS) résout vers `dart:html` ou `dart:io`.
Future<String> downloadCsv({required String fileName, required String content}) {
  throw UnsupportedError('Export CSV non disponible sur cette plateforme.');
}
