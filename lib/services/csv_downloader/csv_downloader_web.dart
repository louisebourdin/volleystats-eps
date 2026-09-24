import 'dart:html' as html;

/// Déclenche un téléchargement navigateur classique (lien invisible cliqué
/// automatiquement), sans dépendance externe.
Future<String> downloadCsv({required String fileName, required String content}) async {
  final bytes = html.Blob([content], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(bytes);
  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..setAttribute('download', fileName);
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return 'Téléchargé : $fileName';
}
