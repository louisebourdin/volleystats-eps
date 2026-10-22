import 'package:flutter_test/flutter_test.dart';
import 'package:volleystats_eps/models/court_zone.dart';
import 'package:volleystats_eps/models/session.dart';
import 'package:volleystats_eps/services/demo_data_service.dart';
import 'package:volleystats_eps/services/sheets_sync_service.dart';

void main() {
  test('summaryRow condense la série en une ligne : objectif et services qui le respectent', () {
    final session = DemoDataService.buildDemoSession().copyWith(
      targetZones: [CourtZones.zone5, CourtZones.zone6],
      mode: SessionMode.avecReception,
      receptionZones: [CourtZones.zone1],
    );

    final row = SheetsSyncService.summaryRow(session);

    expect(row.length, SheetsSyncService.columns.length);
    expect(row[0], session.student.name);
    expect(row[3], 'Avec réception');
    expect(row[4], '10');
    expect(row[5], contains('5'));
    expect(row[5], contains('6'));
    expect(row[6], contains('1'));
    // La série de démo a 6 services dans la zone 5 et 1 dans la zone 6 (§30).
    expect(row[7], '7 / 10');
  });

  test('retire le segment /u/<n>/ ajouté par Google en multi-comptes', () {
    expect(
      SheetsSyncService.normalizeUrl(' https://script.google.com/macros/u/1/s/ABC/exec '),
      'https://script.google.com/macros/s/ABC/exec',
    );
  });

  test('laisse une URL déjà correcte inchangée', () {
    const url = 'https://script.google.com/macros/s/ABC/exec';
    expect(SheetsSyncService.normalizeUrl(url), url);
  });
}
