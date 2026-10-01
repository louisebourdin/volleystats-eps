import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/session.dart';
import 'csv_export_service.dart';

/// Envoie une série vers un Google Sheets, via le Web App Apps Script décrit
/// dans google_apps_script/Code.gs (à coller dans Extensions > Apps Script du
/// tableur). Réutilise les mêmes colonnes/ordre que l'export CSV : les deux
/// restent toujours cohérents.
class SheetsSyncService {
  /// Nettoie l'URL collée : retire les espaces et le segment `/u/<n>/` que
  /// Google ajoute quand on est connecté à plusieurs comptes
  /// (`.../macros/u/1/s/...`). Avec ce segment, l'URL ne marche que dans le
  /// navigateur de ce compte-là ; appelée depuis l'appli, Google répond 404.
  static String normalizeUrl(String url) =>
      url.trim().replaceFirst(RegExp(r'/macros/u/\d+/s/'), '/macros/s/');

  static Future<void> send({required Session session, required String webhookUrl}) async {
    final dataRows = CsvExportService.rows(session).skip(1).toList(); // sans l'en-tête, déjà sur le Sheet

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(normalizeUrl(webhookUrl)),
        // text/plain évite le préflight CORS (Apps Script ne répond pas aux
        // requêtes OPTIONS) : le corps reste du JSON, juste pas déclaré comme tel.
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode({'rows': dataRows}),
      );
    } catch (_) {
      throw Exception('Impossible de contacter Google Sheets (réseau, ou lien invalide).');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Sheets a répondu une erreur (${response.statusCode}).');
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      if (response.body.contains('doPost')) {
        throw Exception(
          'Le script Google ne contient pas la fonction doPost : colle le code de '
          'google_apps_script/Code.gs, enregistre, puis redéploie une nouvelle version.',
        );
      }
      throw Exception(
        'Réponse inattendue — vérifie que le Web App est bien déployé en accès "Tous les utilisateurs".',
      );
    }
    if (decoded['status'] != 'ok') {
      throw Exception(decoded['message']?.toString() ?? 'Erreur inconnue côté Google Sheets.');
    }
  }
}
