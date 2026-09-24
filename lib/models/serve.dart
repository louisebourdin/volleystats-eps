import 'serve_enums.dart';

const Object _sentinel = Object();

/// Un service de volley-ball observé, avec toutes ses caractéristiques.
/// Voir cahier des charges section 22 pour la liste des champs minimaux.
class Serve {
  final String id;
  final String sessionId;
  final int number; // 1..10
  final DateTime timestamp;

  final ServeResult result;
  final String? zone; // CourtZones.* — uniquement renseigné si result == inCourt
  final double positionX; // normalisé 0..1 (peut légèrement dépasser pour les OUT)
  final double positionY; // normalisé 0..1

  final bool footFault;
  final String serveTypeId; // ServeTypes.*
  final ServeTrajectory trajectory;
  final ServeDirection direction;

  // Caractéristiques complémentaires facultatives.
  final TossQuality? tossQuality;
  final ContactQuality? contactQuality;
  final ServePower? power;
  final ServeIntention? intention;

  /// Zone (CourtZones.*, Piscine incluse) où atterrit la réception adverse,
  /// et qualité de cette réception (mode avec réception uniquement, et
  /// seulement pour les services IN).
  final String? receptionZone;
  final ReceptionQuality? receptionQuality;

  const Serve({
    required this.id,
    required this.sessionId,
    required this.number,
    required this.timestamp,
    required this.result,
    required this.positionX,
    required this.positionY,
    this.zone,
    this.footFault = false,
    required this.serveTypeId,
    required this.trajectory,
    required this.direction,
    this.tossQuality,
    this.contactQuality,
    this.power,
    this.intention,
    this.receptionZone,
    this.receptionQuality,
  });

  bool get isIn => result == ServeResult.inCourt;

  Serve copyWith({
    String? id,
    String? sessionId,
    int? number,
    DateTime? timestamp,
    ServeResult? result,
    Object? zone = _sentinel,
    double? positionX,
    double? positionY,
    bool? footFault,
    String? serveTypeId,
    ServeTrajectory? trajectory,
    ServeDirection? direction,
    Object? tossQuality = _sentinel,
    Object? contactQuality = _sentinel,
    Object? power = _sentinel,
    Object? intention = _sentinel,
    Object? receptionZone = _sentinel,
    Object? receptionQuality = _sentinel,
  }) {
    return Serve(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      number: number ?? this.number,
      timestamp: timestamp ?? this.timestamp,
      result: result ?? this.result,
      zone: identical(zone, _sentinel) ? this.zone : zone as String?,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      footFault: footFault ?? this.footFault,
      serveTypeId: serveTypeId ?? this.serveTypeId,
      trajectory: trajectory ?? this.trajectory,
      direction: direction ?? this.direction,
      tossQuality: identical(tossQuality, _sentinel) ? this.tossQuality : tossQuality as TossQuality?,
      contactQuality:
          identical(contactQuality, _sentinel) ? this.contactQuality : contactQuality as ContactQuality?,
      power: identical(power, _sentinel) ? this.power : power as ServePower?,
      intention: identical(intention, _sentinel) ? this.intention : intention as ServeIntention?,
      receptionZone: identical(receptionZone, _sentinel) ? this.receptionZone : receptionZone as String?,
      receptionQuality: identical(receptionQuality, _sentinel)
          ? this.receptionQuality
          : receptionQuality as ReceptionQuality?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'number': number,
        'timestamp': timestamp.toIso8601String(),
        'result': result.name,
        'zone': zone,
        'positionX': positionX,
        'positionY': positionY,
        'footFault': footFault,
        'serveTypeId': serveTypeId,
        'trajectory': trajectory.name,
        'direction': direction.name,
        'tossQuality': tossQuality?.name,
        'contactQuality': contactQuality?.name,
        'power': power?.name,
        'intention': intention?.name,
        'receptionZone': receptionZone,
        'receptionQuality': receptionQuality?.name,
      };

  factory Serve.fromJson(Map<dynamic, dynamic> json) => Serve(
        id: json['id'] as String,
        sessionId: json['sessionId'] as String,
        number: json['number'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        result: ServeResultX.fromName(json['result'] as String),
        zone: json['zone'] as String?,
        positionX: (json['positionX'] as num).toDouble(),
        positionY: (json['positionY'] as num).toDouble(),
        footFault: json['footFault'] as bool? ?? false,
        serveTypeId: json['serveTypeId'] as String? ?? ServeTypes.tennis.id,
        trajectory: ServeTrajectoryX.fromName(json['trajectory'] as String? ?? 'cloche'),
        direction: ServeDirectionX.fromName(json['direction'] as String? ?? 'centre'),
        tossQuality: TossQualityX.fromName(json['tossQuality'] as String?),
        contactQuality: ContactQualityX.fromName(json['contactQuality'] as String?),
        power: ServePowerX.fromName(json['power'] as String?),
        intention: ServeIntentionX.fromName(json['intention'] as String?),
        receptionZone: json['receptionZone'] as String?,
        receptionQuality: ReceptionQualityX.fromName(json['receptionQuality'] as String?),
      );
}
