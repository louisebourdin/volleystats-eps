import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import '../providers/history_provider.dart';
import '../services/recommendation_engine.dart';
import '../services/statistics_service.dart';
import '../theme/app_colors.dart';
import '../utils/french_date.dart';
import '../utils/responsive.dart';
import '../widgets/confirm_dialog.dart';
import 'results_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: SafeArea(
        child: sessions.isEmpty
            ? const _EmptyHistory()
            : Center(
                child: MaxWidthCenter(
                  maxWidth: 900,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final analysis = StatisticsService.analyze(session);
                      final axis = RecommendationEngine.generate(analysis).first.title;
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ResultsScreen(session: session)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${analysis.inCount}/${analysis.total}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${session.student.name}${session.student.className.isNotEmpty ? ' · ${session.student.className}' : ''}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(formatShortFrenchDate(session.date),
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${analysis.successRatePercent.round()} % de réussite · ${analysis.distinctZonesUsed} zone(s)'
                                        '${session.mode == SessionMode.avecReception ? ' · Avec réception' : ''} · $axis',
                                        style: const TextStyle(fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
                                  onPressed: () async {
                                    final confirmed = await showConfirmDialog(
                                      context,
                                      title: 'Supprimer cette série ?',
                                      message: 'Cette action est définitive.',
                                      confirmLabel: 'Supprimer',
                                    );
                                    if (confirmed) {
                                      ref.read(historyProvider.notifier).remove(session.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Aucune série enregistrée pour l\'instant.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lance une nouvelle série ou charge la démonstration depuis l\'accueil.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
