import '../models/court_zone.dart';
import '../models/serve_enums.dart';
import '../models/session.dart';
import '../utils/french_date.dart';

/// Génère un export CSV (séparateur `;`, lisible directement par Excel FR)
/// des 10 services d'une série. Aucune dépendance à la plateforme : le
/// contenu est une simple chaîne de caractères, à charge de l'appelant de
/// la proposer au téléchargement (voir csv_downloader/).
class CsvExportService {
  static const _columns = [
    'Eleve',
    'Classe',
    'Date',
    'Mode',
    'Numero',
    'Resultat',
    'Zone',
    'Type de service',
    'Trajectoire',
    'Ligne de fond mordue',
    'Qualite du lancer',
    'Zone de reception',
    'Qualite de la reception',
  ];

  static String build(Session session) {
    final buffer = StringBuffer()
      ..write('﻿'); // BOM UTF-8 : accents affichés correctement à l'ouverture directe dans Excel.
    buffer.writeln(_columns.map(_escape).join(';'));

    for (final s in session.serves) {
      final row = [
        session.student.name,
        session.student.className,
        formatShortFrenchDate(session.date),
        session.mode.label,
        s.number.toString(),
        s.result.label,
        s.zone != null ? CourtZones.label(s.zone!) : '',
        ServeTypes.byId(s.serveTypeId).label,
        s.trajectory.shortLabel,
        s.footFault ? 'Oui' : 'Non',
        s.tossQuality?.label ?? '',
        s.receptionZone != null ? CourtZones.label(s.receptionZone!) : '',
        s.receptionQuality?.label ?? '',
      ];
      buffer.writeln(row.map(_escape).join(';'));
    }

    return buffer.toString();
  }

  /// Nom de fichier suggéré, sans caractères problématiques pour un système
  /// de fichiers (espaces/accents remplacés).
  static String suggestedFileName(Session session) {
    final safeName = session.student.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final dd = session.date.day.toString().padLeft(2, '0');
    final mm = session.date.month.toString().padLeft(2, '0');
    final yyyy = session.date.year.toString();
    return 'volleystats_${safeName.isEmpty ? 'eleve' : safeName}_$dd-$mm-$yyyy.csv';
  }

  static String _escape(String field) {
    if (field.contains(';') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
