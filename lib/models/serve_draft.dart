import 'serve_enums.dart';

const Object _sentinel = Object();

/// État du formulaire en cours de saisie pour le service actuel.
/// Distinct de [Serve] : reste modifiable/incomplet tant que l'observateur
/// n'a pas appuyé sur "Enregistrer le service".
class ServeDraft {
  final ServeResult? result;
  final String? zone;
  final double? positionX;
  final double? positionY;
  final bool footFault;
  final String serveTypeId;
  final ServeTrajectory trajectory;
  final ServeDirection? direction;
  final TossQuality? tossQuality;
  final String? receptionZone;
  final ReceptionQuality? receptionQuality;

  const ServeDraft({
    this.result,
    this.zone,
    this.positionX,
    this.positionY,
    this.footFault = false,
    this.serveTypeId = 'tennis',
    this.trajectory = ServeTrajectory.tendue,
    this.direction,
    this.tossQuality,
    this.receptionZone,
    this.receptionQuality,
  });

  /// Un service est enregistrable dès qu'un impact a été touché sur le terrain
  /// (et qu'une zone est choisie si le résultat est IN).
  bool get isRecordable {
    if (result == null) return false;
    if (result == ServeResult.inCourt && zone == null) return false;
    return true;
  }

  ServeDraft copyWith({
    Object? result = _sentinel,
    Object? zone = _sentinel,
    Object? positionX = _sentinel,
    Object? positionY = _sentinel,
    bool? footFault,
    String? serveTypeId,
    ServeTrajectory? trajectory,
    Object? direction = _sentinel,
    Object? tossQuality = _sentinel,
    Object? receptionZone = _sentinel,
    Object? receptionQuality = _sentinel,
  }) {
    return ServeDraft(
      result: identical(result, _sentinel) ? this.result : result as ServeResult?,
      zone: identical(zone, _sentinel) ? this.zone : zone as String?,
      positionX: identical(positionX, _sentinel) ? this.positionX : positionX as double?,
      positionY: identical(positionY, _sentinel) ? this.positionY : positionY as double?,
      footFault: footFault ?? this.footFault,
      serveTypeId: serveTypeId ?? this.serveTypeId,
      trajectory: trajectory ?? this.trajectory,
      direction: identical(direction, _sentinel) ? this.direction : direction as ServeDirection?,
      tossQuality: identical(tossQuality, _sentinel) ? this.tossQuality : tossQuality as TossQuality?,
      receptionZone: identical(receptionZone, _sentinel) ? this.receptionZone : receptionZone as String?,
      receptionQuality: identical(receptionQuality, _sentinel)
          ? this.receptionQuality
          : receptionQuality as ReceptionQuality?,
    );
  }
}
