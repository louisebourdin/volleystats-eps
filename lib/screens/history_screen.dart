import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session.dart';
import '../models/student.dart';
import '../providers/history_provider.dart';
import '../services/demo_data_service.dart';
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
    final currentClass = ref.watch(currentClassProvider);
    final allSessions = ref.watch(historyProvider);
    // Séries de la classe choisie (partagées entre appareils) + séries restées
    // locales (démo, anciennes séries sans classe).
    final sessions = currentClass == null
        ? allSessions
        : allSessions
              .where(
                (s) =>
                    classKey(s.student.className) == classKey(currentClass) ||
                    DemoDataService.isDemo(s) ||
                    s.student.className.trim().isEmpty,
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Historique'), actions: const [_SyncButton()]),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: MaxWidthCenter(
                maxWidth: 900,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: DropdownButtonFormField<String>(
                    initialValue: kSchoolClasses.contains(currentClass) ? currentClass : null,
                    decoration: const InputDecoration(labelText: 'Classe', prefixIcon: Icon(Icons.groups_outlined)),
                    hint: const Text('Choisis une classe'),
                    items: [for (final c in kSchoolClasses) DropdownMenuItem(value: c, child: Text(c))],
                    onChanged: (value) {
                      if (value != null) ref.read(historyProvider.notifier).setCurrentClass(value);
                    },
                  ),
                ),
              ),
            ),
            Expanded(
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
                                onTap: () =>
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(builder: (_) => ResultsScreen(session: session))),
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
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
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
                                            Text(
                                              formatShortFrenchDate(session.date),
                                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                            ),
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
          ],
        ),
      ),
    );
  }
}

class _SyncButton extends ConsumerWidget {
  const _SyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    if (status == SyncStatus.disabled) return const SizedBox.shrink();
    if (status == SyncStatus.syncing) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final offline = status == SyncStatus.offline;
    return IconButton(
      tooltip: offline
          ? 'Hors ligne : les séries seront envoyées plus tard. Réessayer'
          : 'Historique de classe à jour. Actualiser',
      icon: Icon(offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded),
      onPressed: () => ref.read(historyProvider.notifier).sync(),
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
