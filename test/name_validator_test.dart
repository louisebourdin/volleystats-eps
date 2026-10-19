import 'package:flutter_test/flutter_test.dart';
import 'package:volleystats_eps/utils/name_validator.dart';

void main() {
  test('accepte les prénoms normaux', () {
    for (final name in [
      'Louise', 'Jean-Baptiste', "N'Golo", 'Chloé', 'Anna', 'Emma', 'Constance',
      'Monique', 'Nicolas', 'Inès', 'Lyn', 'Marie Anne', 'Zoé', 'Matthieu',
    ]) {
      expect(validateName(name), isNull, reason: name);
    }
  });

  test('refuse les noms farfelus ou grossiers', () {
    for (final name in [
      'x', 'aaaa', 'Looool', 'bcdfg', 'Con', 'connard', 'CONNNARD', 'Salope',
      'ta mère', 'fils de pute', 'Merdeee', 'Hitler', 'Pd', 'lol', 'Enculé',
      'Kevin123', 'Toto', 'Batârd',
    ]) {
      expect(validateName(name), isNotNull, reason: name);
    }
  });

  test('champ vide : pas de message, et espaces nettoyés', () {
    expect(validateName('   '), isNull);
    expect(cleanName('  Marie   Anne '), 'Marie Anne');
  });
}
