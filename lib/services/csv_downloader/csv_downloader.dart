/// Point d'entrée unique : redirige vers l'implémentation qui correspond à
/// la plateforme de compilation (web ou mobile/desktop), choisie au moment
/// de la compilation via les imports conditionnels ci-dessous.
///
/// Retourne un message à afficher à l'utilisateur (ex: "Téléchargé" côté
/// web, ou le chemin du fichier enregistré côté mobile/desktop).
library;

export 'csv_downloader_stub.dart'
    if (dart.library.html) 'csv_downloader_web.dart'
    if (dart.library.io) 'csv_downloader_io.dart';
