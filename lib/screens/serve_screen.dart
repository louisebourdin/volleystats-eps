import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/court_zone.dart';
import '../models/serve.dart';
import '../models/serve_enums.dart';
import '../providers/history_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/court/court_marker.dart';
import '../widgets/court/volley_court_widget.dart';
import '../widgets/serve_form.dart';
import '../widgets/serve_progress_indicator.dart';
import 'results_screen.dart';

/// L'écran le plus important de l'application : observer → toucher le
/// terrain → sélectionner quelques caractéristiques → enregistrer, le tout
/// en quelques secondes (§32).
class ServeScreen extends ConsumerWidget {
  const ServeScreen({super.key});

  Future<void> _confirmExit(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Quitter la série ?',
      message: 'La série en cours n\'est pas terminée. Si tu quittes maintenant, elle ne sera pas enregistrée '
          'dans l\'historique.',
      confirmLabel: 'Quitter',
    );
    if (confirmed) {
      ref.read(sessionProvider.notifier).clear();
      if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _handleSave(WidgetRef ref) {
    ref.read(sessionProvider.notifier).saveCurrentServe();
  }

  Future<void> _handleContinue(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider).session!;
    if (session.isComplete) {
      await ref.read(historyProvider.notifier).addOrUpdate(session);
      if (context.mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ResultsScreen()));
      }
    } else {
      ref.read(sessionProvider.notifier).continueToNextServe();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionProvider);
    final session = state.session;
    if (session == null) {
      // Garde-fou : on ne devrait jamais arriver ici sans série démarrée.
      return const Scaffold(body: Center(child: Text('Aucune série en cours.')));
    }
    final draft = state.draft;
    final awaitingContinue = state.awaitingContinue;
    final displayNumber = awaitingContinue ? session.serves.length : session.nextServeNumber;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _confirmExit(context, ref),
          ),
          title: Text(session.student.name),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServeProgressIndicator(current: displayNumber),
                if (session.hasTargetZones) ...[
                  const SizedBox(height: 10),
                  _TargetZonesBanner(zoneIds: session.targetZones),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: awaitingContinue
                      ? _ConfirmationView(serve: session.serves.last)
                      : ResponsiveBuilder(
                          builder: (context, size, constraints) {
                            final court = VolleyCourtWidget(
                              onTap: (result, x, y) => ref.read(sessionProvider.notifier).setImpact(result, x, y),
                              highlightZone: draft.zone,
                              targetZones: session.targetZones.toSet(),
                              markers: draft.positionX == null || draft.positionY == null
                                  ? const []
                                  : [
                                      CourtMarker(
                                        x: draft.positionX!,
                                        y: draft.positionY!,
                                        color: switch (draft.result) {
                                          ServeResult.inCourt => AppColors.success,
                                          ServeResult.net => AppColors.warning,
                                          ServeResult.out || null => AppColors.error,
                                        },
                                      ),
                                    ],
                            );
                            if (size == ScreenSize.mobile) {
                              return SingleChildScrollView(
                                child: Column(
                                  children: [
                                    court,
                                    const SizedBox(height: 20),
                                    const ServeForm(),
                                  ],
                                ),
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Center(child: Padding(padding: const EdgeInsets.only(top: 8), child: court)),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  flex: 4,
                                  child: SingleChildScrollView(child: const ServeForm()),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                if (awaitingContinue)
                  ElevatedButton.icon(
                    onPressed: () => _handleContinue(context, ref),
                    icon: Icon(session.isComplete ? Icons.bar_chart_rounded : Icons.arrow_forward_rounded),
                    label: Text(session.isComplete ? 'Voir le bilan' : 'Continuer'),
                  )
                else
                  _BottomActions(
                    canRecord: draft.isRecordable,
                    canGoBack: session.serves.isNotEmpty,
                    onReset: () => ref.read(sessionProvider.notifier).resetDraft(),
                    onBack: () => ref.read(sessionProvider.notifier).editPreviousServe(),
                    onSave: () => _handleSave(ref),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final bool canRecord;
  final bool canGoBack;
  final VoidCallback onReset;
  final VoidCallback onBack;
  final VoidCallback onSave;

  const _BottomActions({
    required this.canRecord,
    required this.canGoBack,
    required this.onReset,
    required this.onBack,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (canGoBack) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                label: const Text('Réinitialiser'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: canRecord ? onSave : null,
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: const Text('Enregistrer le service'),
        ),
      ],
    );
  }
}

/// Rappel discret des zones que l'élève a choisi de travailler pour la
/// séance (icône + texte + couleur, jamais la couleur seule — §26).
class _TargetZonesBanner extends StatelessWidget {
  final List<String> zoneIds;

  const _TargetZonesBanner({required this.zoneIds});

  @override
  Widget build(BuildContext context) {
    final labels = (zoneIds.toList()..sort()).map(CourtZones.label).join(', ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Objectif de la séance : $labels',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// Écran de confirmation affiché juste après "Enregistrer le service", avant
/// de passer au suivant (bouton "Continuer" en bas de l'écran).
class _ConfirmationView extends StatelessWidget {
  final Serve serve;

  const _ConfirmationView({required this.serve});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String resultLabel;
    switch (serve.result) {
      case ServeResult.inCourt:
        color = AppColors.success;
        icon = Icons.check_rounded;
        resultLabel = serve.zone == 'piscine' ? 'IN — Piscine' : 'IN — Zone ${serve.zone?.replaceAll('zone', '')}';
        break;
      case ServeResult.out:
        color = AppColors.error;
        icon = Icons.close_rounded;
        resultLabel = 'OUT';
        break;
      case ServeResult.net:
        color = AppColors.warning;
        icon = Icons.block_rounded;
        resultLabel = 'FILET';
        break;
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 44),
            ),
            const SizedBox(height: 20),
            Text(
              'Service ${serve.number} enregistré',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(resultLabel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                    const SizedBox(height: 8),
                    Text(
                      '${ServeTypes.byId(serve.serveTypeId).label} · ${serve.trajectory.shortLabel}'
                      '${serve.zone != null && CourtZones.depthLabel(serve.zone!) != null ? ' · ${CourtZones.depthLabel(serve.zone!)}' : ''}'
                      '${serve.receptionQuality != null ? ' · ${serve.receptionQuality!.label}' : ''}'
                      '${serve.footFault ? ' · Ligne mordue' : ''}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
