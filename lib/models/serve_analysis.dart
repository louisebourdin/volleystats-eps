import 'court_zone.dart';
import 'serve_enums.dart';

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

  /// Mode "avec réception" uniquement : clés = ReceptionQuality.name, décompte
  /// des services IN pour lesquels la qualité de la réception a été relevée.
  final Map<String, int> receptionQualityCounts;

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
    this.receptionQualityCounts = const {},
  });

  double get successRatePercent => total == 0 ? 0 : (inCount / total) * 100;

  List<MapEntry<String, int>> get zoneCountsOrdered =>
      CourtZones.orderedForStats.map((z) => MapEntry(z, zoneCounts[z] ?? 0)).toList();

  /// Nombre de services IN dans une zone courte (2, 3, 4).
  int get shortServeCount =>
      zoneCounts.entries.where((e) => CourtZones.isShort(e.key)).fold(0, (sum, e) => sum + e.value);

  /// Nombre de services IN dans une zone longue (5, 6, 1).
  int get longServeCount =>
      zoneCounts.entries.where((e) => CourtZones.isLong(e.key)).fold(0, (sum, e) => sum + e.value);

  /// Nombre de services pour lesquels une qualité de réception a été relevée
  /// (mode avec réception uniquement).
  int get receptionRecordedCount => receptionQualityCounts.values.fold(0, (a, b) => a + b);

  /// Nombre de services ayant mis l'adversaire en danger : toute réception
  /// qui ne repart pas proprement vers le poste 3.
  int get dangerousServeCount => receptionQualityCounts.entries
      .where((e) => e.key != ReceptionQuality.poste3.name)
      .fold(0, (sum, e) => sum + e.value);

  /// Part des services (parmi ceux dont la réception a été relevée) ayant
  /// mis l'adversaire en danger, en pourcentage.
  double get dangerousServeRate =>
      receptionRecordedCount == 0 ? 0 : dangerousServeCount / receptionRecordedCount * 100;
}
