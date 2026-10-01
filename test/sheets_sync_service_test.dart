import 'package:flutter_test/flutter_test.dart';
import 'package:volleystats_eps/services/sheets_sync_service.dart';

void main() {
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
