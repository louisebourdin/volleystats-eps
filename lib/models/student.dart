import 'serve_enums.dart';

/// Classes proposées dans l'appli. Chacune a son propre historique partagé.
const List<String> kSchoolClasses = ['2e1', '2e2', '2e3', '2e4', '2e5'];

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
