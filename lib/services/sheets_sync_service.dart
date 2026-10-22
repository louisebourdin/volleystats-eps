import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/court_zone.dart';
import '../models/serve_enums.dart';
import '../models/session.dart';
import '../utils/french_date.dart';

/// Envoie le résumé d'une série vers un Google Sheets, via le Web App Apps
/// Script décrit dans google_apps_script/Code.gs (à coller dans Extensions >
/// Apps Script du tableur) : une seule ligne par série envoyée (élève,
/// objectif de la série, et combien de services le respectent) — à la
/// différence de l'export CSV, qui lui reste détaillé service par service.
class SheetsSyncService {
  /// En-têtes à renseigner sur la ligne 1 du tableur (voir aussi le README).
  static const columns = [
    'Eleve',
    'Classe',
    'Date',
    'Mode',
    'Nombre de services',
    'Zone(s) visee(s)',
    'Postes receptionneurs',
    'Services dans la zone visee',
  ];

  /// Nettoie l'URL collée : retire les espaces et le segment `/u/<n>/` que
  /// Google ajoute quand on est connecté à plusieurs comptes
  /// (`.../macros/u/1/s/...`). Avec ce segment, l'URL ne marche que dans le
  /// navigateur de ce compte-là ; appelée depuis l'appli, Google répond 404.
  static String normalizeUrl(String url) =>
      url.trim().replaceFirst(RegExp(r'/macros/u/\d+/s/'), '/macros/s/');

  /// La ligne de résumé envoyée pour [session] (ordre : voir [columns]).
  static List<String> summaryRow(Session session) {
    final targetZoneLabels =
        session.targetZones.isEmpty ? '' : (session.targetZones.toList()..sort()).map(CourtZones.label).join(', ');
    final receptionLabels =
        session.receptionZones.isEmpty ? '' : (session.receptionZones.toList()..sort()).map(CourtZones.label).join(', ');
    final hits =
        session.serves.where((s) => s.result == ServeResult.inCourt && session.targetZones.contains(s.zone)).length;

    return [
      session.student.name,
      session.student.className,
      formatShortFrenchDate(session.date),
      session.mode.label,
      session.serves.length.toString(),
      targetZoneLabels,
      receptionLabels,
      '$hits / ${session.serves.length}',
    ];
  }

  static Future<void> send({required Session session, required String webhookUrl}) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(normalizeUrl(webhookUrl)),
        // text/plain évite le préflight CORS (Apps Script ne répond pas aux
        // requêtes OPTIONS) : le corps reste du JSON, juste pas déclaré comme tel.
        headers: {'Content-Type': 'text/plain;charset=utf-8'},
        body: jsonEncode({
          'rows': [summaryRow(session)],
        }),
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
