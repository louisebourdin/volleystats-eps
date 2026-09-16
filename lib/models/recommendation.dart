import 'package:flutter/material.dart';

enum RecommendationLevel { priority, good, info }

/// Un conseil généré par le moteur de recommandations, avec ses exercices.
class Recommendation {
  final String title;
  final String explanation;
  final List<String> exercises;
  final RecommendationLevel level;
  final IconData icon;

  const Recommendation({
    required this.title,
    required this.explanation,
    required this.exercises,
    required this.level,
    this.icon = Icons.tips_and_updates_outlined,
  });
}

Color recommendationColor(RecommendationLevel level) {
  switch (level) {
    case RecommendationLevel.priority:
      return const Color(0xFFE0752A); // orange — attention
    case RecommendationLevel.good:
      return const Color(0xFF2E9E5B); // vert — réussite
    case RecommendationLevel.info:
      return const Color(0xFF2E6FE0); // bleu — information
  }
}
