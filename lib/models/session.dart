import 'serve.dart';
import 'student.dart';

const int kServesPerSession = 10;

/// Une série de [kServesPerSession] services réalisée par un élève.
class Session {
  final String id;
  final Student student;
  final DateTime date;
  final List<Serve> serves;

  /// Zone(s) que l'élève a choisi de travailler précisément pour cette
  /// séance (parmi CourtZones.zone1..zone6). Vide = entraînement libre.
  final List<String> targetZones;

  const Session({
    required this.id,
    required this.student,
    required this.date,
    this.serves = const [],
    this.targetZones = const [],
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
  }) {
    return Session(
      id: id ?? this.id,
      student: student ?? this.student,
      date: date ?? this.date,
      serves: serves ?? this.serves,
      targetZones: targetZones ?? this.targetZones,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student': student.toJson(),
        'date': date.toIso8601String(),
        'serves': serves.map((s) => s.toJson()).toList(),
        'targetZones': targetZones,
      };

  factory Session.fromJson(Map<dynamic, dynamic> json) => Session(
        id: json['id'] as String,
        student: Student.fromJson(Map<dynamic, dynamic>.from(json['student'] as Map)),
        date: DateTime.parse(json['date'] as String),
        serves: (json['serves'] as List)
            .map((e) => Serve.fromJson(Map<dynamic, dynamic>.from(e as Map)))
            .toList(),
        targetZones: (json['targetZones'] as List?)?.map((e) => e as String).toList() ?? const [],
      );
}
