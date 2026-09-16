import 'serve_enums.dart';

class Student {
  final String name; // prénom ou pseudonyme
  final String className;
  final DominantHand dominantHand;
  final String mainServeTypeId; // ServeTypes.*

  const Student({
    required this.name,
    required this.className,
    required this.dominantHand,
    required this.mainServeTypeId,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'className': className,
        'dominantHand': dominantHand.name,
        'mainServeTypeId': mainServeTypeId,
      };

  factory Student.fromJson(Map<dynamic, dynamic> json) => Student(
        name: json['name'] as String? ?? 'Élève',
        className: json['className'] as String? ?? '',
        dominantHand: DominantHandX.fromName(json['dominantHand'] as String? ?? 'droitier'),
        mainServeTypeId: json['mainServeTypeId'] as String? ?? ServeTypes.tennis.id,
      );
}
