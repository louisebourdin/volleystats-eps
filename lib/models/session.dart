import 'serve.dart';
import 'student.dart';

const int kServesPerSession = 10;

/// Une série peut être analysée seule (défaut) ou avec la réception adverse,
/// pour mesurer le danger provoqué par chaque service (§ nouvelle fonctionnalité).
enum SessionMode { sansReception, avecReception }

extension SessionModeX on SessionMode {
  String get label => this == SessionMode.avecReception ? 'Avec réception' : 'Sans réception';

  static SessionMode fromName(String? name) =>
      SessionMode.values.firstWhere((e) => e.name == name, orElse: () => SessionMode.sansReception);
}

/// Une série de [kServesPerSession] services réalisée par un élève.
class Session {
  final String id;
  final Student student;
  final DateTime date;
  final List<Serve> serves;

  /// Zone(s) que l'élève a choisi de travailler précisément pour cette
  /// séance (parmi CourtZones.zone1..zone6). Vide = entraînement libre.
  final List<String> targetZones;

  /// Sans réception (par défaut) ou avec réception : dans ce second cas, on
  /// relève en plus la qualité de la réception adverse pour chaque service IN.
  final SessionMode mode;

  /// Postes (parmi CourtZones.zone1..zone6) où se trouve un réceptionneur.
  /// Purement informatif/affiché : n'entre dans aucun calcul de statistiques.
  final List<String> receptionZones;

  const Session({
    required this.id,
    required this.student,
    required this.date,
    this.serves = const [],
    this.targetZones = const [],
    this.mode = SessionMode.sansReception,
    this.receptionZones = const [],
  });

  bool get isComplete => serves.length >= kServesPerSession;
  int get nextServeNumber => serves.length + 1;
  bool get hasTargetZones => targetZones.isNotEmpty;

  Session copyWith({
    String? id,
    Student? student,
    DateTime? date,
    List<Serve>? serves,
    List<String>? targetZones,
    SessionMode? mode,
    List<String>? receptionZones,
  }) {
    return Session(
      id: id ?? this.id,
      student: student ?? this.student,
      date: date ?? this.date,
      serves: serves ?? this.serves,
      targetZones: targetZones ?? this.targetZones,
      mode: mode ?? this.mode,
      receptionZones: receptionZones ?? this.receptionZones,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student': student.toJson(),
        'date': date.toIso8601String(),
        'serves': serves.map((s) => s.toJson()).toList(),
        'targetZones': targetZones,
        'mode': mode.name,
        'receptionZones': receptionZones,
      };

  factory Session.fromJson(Map<dynamic, dynamic> json) => Session(
        id: json['id'] as String,
        student: Student.fromJson(Map<dynamic, dynamic>.from(json['student'] as Map)),
        date: DateTime.parse(json['date'] as String),
        serves: (json['serves'] as List)
            .map((e) => Serve.fromJson(Map<dynamic, dynamic>.from(e as Map)))
            .toList(),
        targetZones: (json['targetZones'] as List?)?.map((e) => e as String).toList() ?? const [],
        mode: SessionModeX.fromName(json['mode'] as String?),
        receptionZones: (json['receptionZones'] as List?)?.map((e) => e as String).toList() ?? const [],
      );
}
