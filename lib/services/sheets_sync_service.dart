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
    'Date',
    'Classe',
    'Eleve',
    'Nombre de services',
    'Objectif (zones)',
    'Mode',
    'Services dans la zone visee',
    'Ace ou bonne reception',
  ];

  /// Nettoie l'URL collée : retire les espaces et le segment `/u/<n>/` que
  /// Google ajoute quand on est connecté à plusieurs comptes
  /// (`.../macros/u/1/s/...`). Avec ce segment, l'URL ne marche que dans le
  /// navigateur de ce compte-là ; appelée depuis l'appli, Google répond 404.
  static String normalizeUrl(String url) =>
      url.trim().replaceFirst(RegExp(r'/macros/u/\d+/s/'), '/macros/s/');

  /// L'appli ne sert que des classes de seconde ("2e1".."2e5") : sur Sheets,
  /// la colonne Classe n'affiche que le numéro ("2e1" -> "1"). Si le format
  /// ne contient pas de chiffre (ne devrait pas arriver), renvoie la classe
  /// telle quelle plutôt que de perdre l'information.
  static String _classNumber(String className) =>
      RegExp(r'(\d+)$').firstMatch(className)?.group(1) ?? className;

  static bool _exactly(Set<String> zones, List<String> pattern) =>
      zones.length == pattern.length && pattern.every(zones.contains);

  /// Nomme l'objectif quand les zones choisies correspondent à un schéma
  /// connu (zones avant = services courts, zones arrière = services longs,
  /// les 6 zones = tout le terrain) ; sinon, liste les zones telles quelles.
  static String _objectiveLabel(List<String> targetZones) {
    if (targetZones.isEmpty) return '';
    final zones = targetZones.toSet();
    const allCourtZones = [
      CourtZones.zone1,
      CourtZones.zone2,
      CourtZones.zone3,
      CourtZones.zone4,
      CourtZones.zone5,
      CourtZones.zone6,
    ];
    if (allCourtZones.every(zones.contains)) return 'Tout le terrain';
    if (_exactly(zones, CourtZones.shortZones)) return 'Services courts';
    if (_exactly(zones, CourtZones.longZones)) return 'Services longs';
    return (targetZones.toList()..sort()).map(CourtZones.label).join(', ');
  }

  /// La ligne de résumé envoyée pour [session] (ordre : voir [columns]).
  static List<String> summaryRow(Session session) {
    final objectiveLabel = _objectiveLabel(session.targetZones);
    final hits =
        session.serves.where((s) => s.result == ServeResult.inCourt && session.targetZones.contains(s.zone)).length;
    final aceCount = session.serves.where((s) => s.receptionQuality == ReceptionQuality.ace).length;
    final bonneCount = session.serves.where((s) => s.receptionQuality == ReceptionQuality.bonne).length;
    final receptionSummary =
        session.mode == SessionMode.avecReception ? '$aceCount Ace / $bonneCount Bonne réception' : '';

    return [
      formatShortFrenchDate(session.date),
      _classNumber(session.student.className),
      session.student.name,
      session.serves.length.toString(),
      objectiveLabel,
      session.mode.label,
      '$hits / ${session.serves.length}',
      receptionSummary,
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
