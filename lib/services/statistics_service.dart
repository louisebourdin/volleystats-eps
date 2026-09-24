import '../models/serve_analysis.dart';
import '../models/serve_enums.dart';
import '../models/session.dart';

class SessionComparison {
  final double successRateDelta; // points de pourcentage
  final int zonesDelta;

  const SessionComparison({required this.successRateDelta, required this.zonesDelta});
}

/// Calcule les statistiques d'une série à partir des services bruts.
/// Objectif pédagogique (§16) : ne jamais réduire l'analyse à la seule
/// réussite — régularité, précision, variété et maîtrise technique comptent.
class StatisticsService {
  static ServeAnalysis analyze(Session session) {
    final serves = session.serves;
    final total = serves.length;

    final inServes = serves.where((s) => s.result == ServeResult.inCourt).toList();
    final outCount = serves.where((s) => s.result == ServeResult.out).length;
    final netCount = serves.where((s) => s.result == ServeResult.net).length;
    final footFaultCount = serves.where((s) => s.footFault).length;

    final zoneCounts = <String, int>{};
    for (final s in inServes) {
      if (s.zone == null) continue;
      zoneCounts[s.zone!] = (zoneCounts[s.zone!] ?? 0) + 1;
    }

    final serveTypeCounts = <String, int>{};
    for (final s in serves) {
      serveTypeCounts[s.serveTypeId] = (serveTypeCounts[s.serveTypeId] ?? 0) + 1;
    }

    final fastTrajectoryCount = serves.where((s) => s.trajectory == ServeTrajectory.tendue).length;
    final slowTrajectoryCount = serves.where((s) => s.trajectory == ServeTrajectory.cloche).length;

    final directionCounts = <String, int>{};
    for (final s in serves) {
      directionCounts[s.direction.name] = (directionCounts[s.direction.name] ?? 0) + 1;
    }

    final receptionQualityCounts = <String, int>{};
    for (final s in inServes) {
      final q = s.receptionQuality;
      if (q == null) continue;
      receptionQualityCounts[q.name] = (receptionQualityCounts[q.name] ?? 0) + 1;
    }

    String? dominantZone;
    int dominantZoneCount = 0;
    zoneCounts.forEach((zone, count) {
      if (count > dominantZoneCount) {
        dominantZoneCount = count;
        dominantZone = zone;
      }
    });
    final dominantZoneShare = inServes.isEmpty ? 0.0 : dominantZoneCount / inServes.length;

    final distinctZonesUsed = zoneCounts.keys.where((z) => (zoneCounts[z] ?? 0) > 0).length;
    final varietyLevel = _varietyFor(distinctZonesUsed);

    return ServeAnalysis(
      total: total,
      inCount: inServes.length,
      outCount: outCount,
      netCount: netCount,
      footFaultCount: footFaultCount,
      zoneCounts: zoneCounts,
      serveTypeCounts: serveTypeCounts,
      fastTrajectoryCount: fastTrajectoryCount,
      slowTrajectoryCount: slowTrajectoryCount,
      directionCounts: directionCounts,
      dominantZone: dominantZone,
      dominantZoneShare: dominantZoneShare,
      distinctZonesUsed: distinctZonesUsed,
      varietyLevel: varietyLevel,
      receptionQualityCounts: receptionQualityCounts,
    );
  }

  static VarietyLevel _varietyFor(int distinctZonesUsed) {
    if (distinctZonesUsed <= 1) return VarietyLevel.faible;
    if (distinctZonesUsed <= 3) return VarietyLevel.moyenne;
    return VarietyLevel.elevee;
  }

  /// Comparaison entre deux séries du même élève (§19).
  static SessionComparison compare({required Session previous, required Session current}) {
    final prevStats = analyze(previous);
    final currStats = analyze(current);
    return SessionComparison(
      successRateDelta: currStats.successRatePercent - prevStats.successRatePercent,
      zonesDelta: currStats.distinctZonesUsed - prevStats.distinctZonesUsed,
    );
  }

  /// Points forts textuels affichés dans "Mon analyse" (§18).
  static List<String> strengths(ServeAnalysis a) {
    final points = <String>[];
    if (a.successRatePercent >= 70) {
      points.add('Service régulier (${a.successRatePercent.round()} % de réussite).');
    }
    if (a.footFaultCount == 0) {
      points.add('Aucune faute de pied.');
    } else if (a.footFaultCount <= 1) {
      points.add('Très peu de fautes de pied.');
    }
    if (a.netCount == 0) {
      points.add('Aucun service dans le filet.');
    }
    if (a.varietyLevel == VarietyLevel.elevee) {
      points.add('Bonne variété de zones visées.');
    }
    String? bestType;
    int bestTypeCount = 0;
    a.serveTypeCounts.forEach((type, count) {
      if (count > bestTypeCount) {
        bestTypeCount = count;
        bestType = type;
      }
    });
    if (bestType != null && bestTypeCount >= (a.total / 2).ceil()) {
      points.add('Bonne maîtrise du service ${_serveTypeLabel(bestType!)}.');
    }
    if (points.isEmpty) {
      points.add('Série complète enregistrée : une bonne base pour progresser.');
    }
    return points.take(4).toList();
  }

  static String _serveTypeLabel(String id) {
    switch (id) {
      case 'cuillere':
        return 'cuillère';
      case 'tennis':
        return 'tennis';
      case 'flottant':
        return 'flottant';
      case 'smashe':
        return 'smashé';
      default:
        return id;
    }
  }
}
