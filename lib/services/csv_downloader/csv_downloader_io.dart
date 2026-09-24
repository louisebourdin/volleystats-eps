import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Mobile/desktop : pas de "téléchargement" navigateur, on enregistre le
/// fichier sur l'appareil (dossier Téléchargements si disponible — desktop —
/// sinon le dossier documents de l'application) et on renvoie le chemin
/// pour l'afficher à l'utilisateur.
Future<String> downloadCsv({required String fileName, required String content}) async {
  Directory dir;
  try {
    dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  } catch (_) {
    dir = await getApplicationDocumentsDirectory();
  }
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(content);
  return 'Enregistré : ${file.path}';
}
