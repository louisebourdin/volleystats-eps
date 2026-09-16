import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _steps = [
    (
      Icons.groups_rounded,
      'Travaillez en binôme',
      'Un élève réalise 10 services, l\'autre observe et utilise l\'application.',
    ),
    (
      Icons.person_add_alt_rounded,
      'Renseignez l\'élève',
      'Prénom, classe, main dominante et type de service principal — ça prend 10 secondes.',
    ),
    (
      Icons.touch_app_rounded,
      'Touchez le terrain',
      'Après chaque service, touchez l\'endroit où le ballon est tombé : la zone (1 à 6), la Piscine, le filet ou "out" sont détectés automatiquement.',
    ),
    (
      Icons.checklist_rounded,
      'Précisez quelques détails',
      'Type de service, trajectoire, ligne de fond mordue. Les détails supplémentaires restent facultatifs.',
    ),
    (
      Icons.check_circle_outline_rounded,
      'Enregistrez',
      'Un bouton, et on passe directement au service suivant. Après le 10e service, le bilan s\'affiche tout seul.',
    ),
    (
      Icons.insights_rounded,
      'Découvrez le bilan',
      'Statistiques, carte des impacts, points forts et exercices adaptés à l\'élève.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comment ça marche ?')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: MaxWidthCenter(
            maxWidth: 700,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final step in _steps) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(step.$1, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(step.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                const SizedBox(height: 6),
                                Text(step.$3, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
