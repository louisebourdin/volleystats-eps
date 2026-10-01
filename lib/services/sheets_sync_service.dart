import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/session.dart';
import 'csv_export_service.dart';

/// Envoie une série vers un Google Sheets, via le Web App Apps Script décrit
/// dans google_apps_script/Code.gs (à coller dans Extensions > Apps Script du
/// tableur). Réutilise les mêmes colonnes/ordre que l'export CSV : les deux
/// restent toujours cohérents.
class SheetsSyncService {
  static Future<void> send({required Session session, required String webhookUrl}) async {
    final dataRows = CsvExportService.rows(session).skip(1).toList(); // sans l'en-tête, déjà sur le Sheet

    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(webhookUrl),
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
      throw Exception(
        'Réponse inattendue — vérifie que le Web App est bien déployé en accès "Tous les utilisateurs".',
      );
    }
    if (decoded['status'] != 'ok') {
      throw Exception(decoded['message']?.toString() ?? 'Erreur inconnue côté Google Sheets.');
    }
  }
}
