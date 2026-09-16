import 'package:flutter/material.dart';

import '../models/court_zone.dart';
import '../models/recommendation.dart';
import '../models/serve_analysis.dart';

/// Moteur de conseils à base de règles (§17). Chaque règle correspond à un
/// exemple du cahier des charges. La première règle qui matche devient
/// "l'axe prioritaire" ; des observations secondaires peuvent s'ajouter.
class RecommendationEngine {
  static List<Recommendation> generate(ServeAnalysis a) {
    final recommendations = <Recommendation>[];
    final primary = _primaryRecommendation(a);
    recommendations.add(primary);

    // Observations secondaires, seulement si elles n'ont pas déjà été
    // couvertes par la recommandation principale.
    if (primary.title != _footFaultRec.title && a.footFaultCount >= 2) {
      recommendations.add(_footFaultRec);
    }
    if (primary.title != _netRec.title && a.netCount >= 2 && a.netCount < 3) {
      recommendations.add(_netRec);
    }

    return recommendations;
  }

  static Recommendation _primaryRecommendation(ServeAnalysis a) {
    // Exemple 1 : beaucoup de OUT → priorité régularité.
    if (a.outCount >= 7) {
      return const Recommendation(
        title: 'Priorité : retrouver de la régularité',
        explanation:
            'Une grande partie de tes services termine hors du terrain. Avant de chercher la puissance ou les '
            'zones difficiles, travaille la répétition du geste.',
        exercises: [
          'Répétition du geste sans ballon',
          'Services à faible puissance',
          'Services à courte distance',
          'Séries de 10 services en visant simplement l\'intérieur du terrain',
        ],
        level: RecommendationLevel.priority,
        icon: Icons.gps_fixed_rounded,
      );
    }

    // Exemple 3 : beaucoup de services dans le filet.
    if (a.netCount >= 3) {
      return _netRec;
    }

    // Exemple 4 : beaucoup de fautes de pied.
    if (a.footFaultCount >= 3) {
      return _footFaultRec;
    }

    // Exemple 2 : très bonne réussite mais concentrée sur une seule zone.
    if (a.inCount >= 8 && a.dominantZoneShare >= 0.7) {
      final zoneLabel = a.dominantZone != null ? CourtZones.label(a.dominantZone!) : 'une même zone';
      return Recommendation(
        title: 'Très bonne régularité, travaille maintenant la variation',
        explanation:
            'Tes services sont réguliers, mais la plupart atterrissent en $zoneLabel. Apprendre à varier tes '
            'zones rendra ton service beaucoup plus difficile à réceptionner.',
        exercises: const [
          'Viser alternativement zone 1 et zone 5',
          'Viser gauche / droite',
          'Placer des cibles au sol',
          'Réaliser 3 services dans trois zones différentes',
        ],
        level: RecommendationLevel.good,
        icon: Icons.shuffle_rounded,
      );
    }

    // Exemple 5 : régulier ET varié.
    if (a.inCount >= 8 && a.distinctZonesUsed >= 3) {
      return const Recommendation(
        title: 'Service régulier et varié',
        explanation: 'Bravo, ton service est fiable et bien réparti sur le terrain. Le nouvel objectif : progresser '
            'en puissance et en difficulté pour l\'adversaire.',
        exercises: [
          'Augmenter progressivement la vitesse',
          'Viser les espaces libres',
          'Travailler les zones difficiles',
          'Varier entre service flottant et service puissant',
        ],
        level: RecommendationLevel.good,
        icon: Icons.emoji_events_outlined,
      );
    }

    // Repli : performance moyenne, pas de signal extrême.
    if (a.successRatePercent < 50) {
      return const Recommendation(
        title: 'Priorité : sécuriser ton service',
        explanation: 'Un peu plus de la moitié de tes services ne passent pas. Concentre-toi sur un geste simple '
            'et répétable avant de viser des zones précises.',
        exercises: [
          'Services à faible puissance en visant le centre du terrain',
          'Travail face à un mur',
          'Répétition du lancer de balle seul',
          'Séries courtes de 5 services en visant uniquement "dedans"',
        ],
        level: RecommendationLevel.priority,
        icon: Icons.restart_alt_rounded,
      );
    }

    return const Recommendation(
      title: 'Bonne base, continue à consolider',
      explanation: 'Ta série est correcte. Continue à répéter le geste pour gagner en régularité, puis travaille '
          'progressivement la précision des zones.',
      exercises: [
        'Séries de 10 services en visant l\'intérieur du terrain',
        'Viser alternativement 2 zones',
        'Travailler le contact avec le ballon',
      ],
      level: RecommendationLevel.info,
      icon: Icons.trending_up_rounded,
    );
  }

  static const _footFaultRec = Recommendation(
    title: 'Attention à ta position de départ',
    explanation: 'Plusieurs services montrent une ligne de fond mordue (faute de pied).',
    exercises: [
      'Commencer légèrement plus loin derrière la ligne',
      'Stabiliser les appuis avant l\'armer du bras',
      'Travailler le geste sans chercher immédiatement la puissance',
    ],
    level: RecommendationLevel.priority,
    icon: Icons.warning_amber_rounded,
  );

  static const _netRec = Recommendation(
    title: 'Travaille la hauteur et le contact avec le ballon',
    explanation: 'Plusieurs services terminent dans le filet.',
    exercises: [
      'Vérifier le lancer de balle',
      'Contacter le ballon devant soi',
      'Terminer le geste vers la cible',
      'Réduire temporairement la puissance',
    ],
    level: RecommendationLevel.priority,
    icon: Icons.sports_volleyball_outlined,
  );
}
