import 'court_zone.dart';

enum VarietyLevel { faible, moyenne, elevee }

extension VarietyLevelX on VarietyLevel {
  String get label {
    switch (this) {
      case VarietyLevel.faible:
        return 'Variété faible';
      case VarietyLevel.moyenne:
        return 'Variété moyenne';
      case VarietyLevel.elevee:
        return 'Variété élevée';
    }
  }
}

/// Analyse calculée d'une série de services (jamais persistée telle quelle :
/// toujours recalculée depuis les [Serve] bruts, qui restent la source de vérité).
class ServeAnalysis {
  final int total;
  final int inCount;
  final int outCount;
  final int netCount;
  final int footFaultCount;

  final Map<String, int> zoneCounts; // clés = CourtZones.*, uniquement les IN
  final Map<String, int> serveTypeCounts; // clés = ServeTypes id
  final int fastTrajectoryCount; // "tendue"
  final int slowTrajectoryCount; // "cloche"
  final Map<String, int> directionCounts; // gauche/centre/droite

  final String? dominantZone;
  final double dominantZoneShare; // 0..1, part des IN dans la zone dominante
  final int distinctZonesUsed;
  final VarietyLevel varietyLevel;

  const ServeAnalysis({
    required this.total,
    required this.inCount,
    required this.outCount,
    required this.netCount,
    required this.footFaultCount,
    required this.zoneCounts,
    required this.serveTypeCounts,
    required this.fastTrajectoryCount,
    required this.slowTrajectoryCount,
    required this.directionCounts,
    required this.dominantZone,
    required this.dominantZoneShare,
    required this.distinctZonesUsed,
    required this.varietyLevel,
  });

  double get successRatePercent => total == 0 ? 0 : (inCount / total) * 100;

  List<MapEntry<String, int>> get zoneCountsOrdered =>
      CourtZones.orderedForStats.map((z) => MapEntry(z, zoneCounts[z] ?? 0)).toList();
}
