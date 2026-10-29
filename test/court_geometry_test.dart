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

  group('CourtGeometry.rectForZone — inter zone', () {
    // Régression : le terrain affiché pendant la saisie disparaissait
    // (exception) dès qu'un service tombait sur une ligne, car rectForZone
    // ne savait dessiner que les 6 zones + la Piscine.
    test('ne plante jamais pour une "inter zone" et couvre les deux zones voisines', () {
      for (final interZone in CourtZones.interZones) {
        expect(() => CourtGeometry.rectForZone(interZone), returnsNormally);
      }
      final rect = CourtGeometry.rectForZone(CourtZones.interZone34);
      final rect3 = CourtGeometry.rectForZone(CourtZones.zone3);
      final rect4 = CourtGeometry.rectForZone(CourtZones.zone4);
      expect(rect, rect3.expandToInclude(rect4));
    });
  });

  group('CourtZones — inter zone', () {
    test('une "inter zone" avant est classée "Service court"', () {
      expect(CourtZones.depthLabel(CourtZones.interZone34), 'Service court');
      expect(CourtZones.depthLabel(CourtZones.interZone23), 'Service court');
    });

    test('une "inter zone" arrière est classée "Service long"', () {
      expect(CourtZones.depthLabel(CourtZones.interZone56), 'Service long');
      expect(CourtZones.depthLabel(CourtZones.interZone16), 'Service long');
    });

    test('label() donne un texte lisible, pas l\'identifiant brut', () {
      expect(CourtZones.label(CourtZones.interZone34), 'Inter zone 3-4');
      expect(CourtZones.label(CourtZones.interZone34), isNot(contains('_')));
    });
  });
}
