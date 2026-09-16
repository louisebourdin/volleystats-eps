import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/history_provider.dart';
import '../providers/session_provider.dart';
import '../services/demo_data_service.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'help_screen.dart';
import 'history_screen.dart';
import 'new_session_screen.dart';
import 'results_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: MaxWidthCenter(
              maxWidth: 480,
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12)),
                      ],
                    ),
                    child: const Icon(Icons.sports_volleyball_rounded, color: Colors.white, size: 52),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'VolleyStats EPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Analyse et améliore ton service',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.accent),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Analyse tes services. Comprends tes points forts. Progresse.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewSessionScreen())),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Nouvelle série'),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen())),
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Historique'),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
                    icon: const Icon(Icons.help_outline_rounded),
                    label: const Text('Comment ça marche ?'),
                  ),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.play_circle_outline_rounded, size: 18),
                        label: const Text('Charger une démonstration'),
                        onPressed: () {
                          final demo = DemoDataService.buildDemoSession();
                          final demo2 = DemoDataService.buildDemoSessionImproved();
                          ref.read(historyProvider.notifier).addOrUpdate(demo);
                          ref.read(historyProvider.notifier).addOrUpdate(demo2);
                          ref.read(sessionProvider.notifier).loadCompletedSession(demo2);
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResultsScreen()));
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.school_outlined, size: 18),
                        label: const Text('Mode professeur'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Le mode professeur arrivera dans une prochaine version.')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Créé par Louise, Yovanne et Yanis',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
