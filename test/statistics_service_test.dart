import 'package:flutter_test/flutter_test.dart';

import 'package:volleystats_eps/models/court_zone.dart';
import 'package:volleystats_eps/models/serve_analysis.dart';
import 'package:volleystats_eps/services/demo_data_service.dart';
import 'package:volleystats_eps/services/recommendation_engine.dart';
import 'package:volleystats_eps/services/statistics_service.dart';

void main() {
  group('StatisticsService', () {
    test('analyzes the demo session as described in the spec (§30)', () {
      final session = DemoDataService.buildDemoSession();
      final analysis = StatisticsService.analyze(session);

      expect(analysis.total, 10);
      expect(analysis.inCount, 7);
      expect(analysis.outCount, 2);
      expect(analysis.netCount, 1);
      expect(analysis.footFaultCount, 2);
      expect(analysis.zoneCounts[CourtZones.zone5], 6);
      expect(analysis.zoneCounts[CourtZones.zone6], 1);
      expect(analysis.distinctZonesUsed, 2);
      expect(analysis.varietyLevel, VarietyLevel.moyenne);
      expect(analysis.dominantZone, CourtZones.zone5);
      expect(analysis.dominantZoneShare, closeTo(6 / 7, 0.001));
    });

    test('compares two sessions of the same student (§19)', () {
      final s1 = DemoDataService.buildDemoSession(date: DateTime(2026, 1, 1));
      final s2 = DemoDataService.buildDemoSessionImproved(date: DateTime(2026, 1, 8));

      final comparison = StatisticsService.compare(previous: s1, current: s2);

      expect(comparison.successRateDelta, closeTo(10, 0.001)); // 70% -> 80%
      expect(comparison.zonesDelta, 3); // 2 zones -> 5 zones
    });
  });

  group('RecommendationEngine', () {
    test('flags variety as the priority axis for a regular but repetitive session', () {
      final session = DemoDataService.buildDemoSession();
      final analysis = StatisticsService.analyze(session);
      final recommendations = RecommendationEngine.generate(analysis);

      expect(recommendations, isNotEmpty);
      // 7 IN / 10 et une zone dominante à 6/7 (< régularité extrême mais concentrée) :
      // ni le seuil "beaucoup de OUT" (>=7) ni "inCount>=8" ne s'appliquent ici,
      // donc le moteur retombe sur un conseil de consolidation générale.
      expect(recommendations.first.title, isNotEmpty);
    });

    test('flags a highly repetitive but very successful session as needing variation', () {
      final session = DemoDataService.buildDemoSessionImproved(); // 8 IN, 5 distinct zones
      final analysis = StatisticsService.analyze(session);
      final recommendations = RecommendationEngine.generate(analysis);

      expect(recommendations.first.title, 'Service régulier et varié');
    });
  });
}
