import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:volleystats_eps/models/court_zone.dart';
import 'package:volleystats_eps/models/serve_enums.dart';
import 'package:volleystats_eps/widgets/court/court_geometry.dart';

void main() {
  group('CourtGeometry.resultForPoint — inter zone', () {
    test('un appui au centre d\'une zone reste cette zone', () {
      final center = CourtGeometry.rectForZone(CourtZones.zone3).center;
      final result = CourtGeometry.resultForPoint(center);
      expect(result.result, ServeResult.inCourt);
      expect(result.zone, CourtZones.zone3);
    });

    test('un appui sur la ligne avant entre zone 3 et zone 4', () {
      final boundaryX = CourtGeometry.courtLeft + CourtGeometry.colWidth;
      final y = CourtGeometry.courtTop + 0.01; // loin de la Piscine, côté filet
      final result = CourtGeometry.resultForPoint(Offset(boundaryX, y));
      expect(result.result, ServeResult.inCourt);
      expect(result.zone, CourtZones.interZone34);
    });

    test('un appui sur la ligne avant entre zone 2 et zone 3', () {
      final boundaryX = CourtGeometry.courtLeft + 2 * CourtGeometry.colWidth;
      final y = CourtGeometry.courtTop + 0.01;
      final result = CourtGeometry.resultForPoint(Offset(boundaryX, y));
      expect(result.zone, CourtZones.interZone23);
    });

    test('un appui sur la ligne arrière entre zone 5 et zone 6', () {
      final boundaryX = CourtGeometry.courtLeft + CourtGeometry.colWidth;
      final y = CourtGeometry.courtBottom - 0.01; // loin de la Piscine, côté fond
      final result = CourtGeometry.resultForPoint(Offset(boundaryX, y));
      expect(result.zone, CourtZones.interZone56);
    });

    test('un appui sur la ligne arrière entre zone 6 et zone 1', () {
      final boundaryX = CourtGeometry.courtLeft + 2 * CourtGeometry.colWidth;
      final y = CourtGeometry.courtBottom - 0.01;
      final result = CourtGeometry.resultForPoint(Offset(boundaryX, y));
      expect(result.zone, CourtZones.interZone16);
    });

    test('jamais de ligne inter zone entre l\'avant et l\'arrière', () {
      // Milieu de terrain en x (loin de toute ligne verticale), sur la ligne
      // avant/arrière : doit retomber dans la Piscine ou une zone normale,
      // jamais un "inter zone".
      final result = CourtGeometry.resultForPoint(Offset(CourtGeometry.midX, CourtGeometry.midY));
      expect(CourtZones.isInterZone(result.zone ?? ''), isFalse);
    });

    test('la Piscine reste prioritaire même près d\'une ligne de colonne', () {
      final boundaryX = CourtGeometry.courtLeft + CourtGeometry.colWidth;
      final result = CourtGeometry.resultForPoint(Offset(boundaryX, CourtGeometry.midY));
      expect(result.zone, CourtZones.piscine);
    });

    test('includeInterZones: false (mode sélection de zone) ignore les lignes', () {
      final boundaryX = CourtGeometry.courtLeft + CourtGeometry.colWidth;
      final y = CourtGeometry.courtTop + 0.01;
      final result = CourtGeometry.resultForPoint(Offset(boundaryX, y), includeInterZones: false);
      expect(CourtZones.isInterZone(result.zone ?? ''), isFalse);
    });
  });
}
