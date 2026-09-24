import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/court_zone.dart';
import '../models/serve_draft.dart';
import '../models/serve_enums.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../theme/app_colors.dart';

/// Formulaire rapide d'un service : quelques choix à toucher, rien de plus.
class ServeForm extends ConsumerWidget {
  const ServeForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(sessionProvider).draft;
    final notifier = ref.read(sessionProvider.notifier);
    final session = ref.watch(sessionProvider).session;
    final mode = session?.mode ?? SessionMode.sansReception;
    final targetZones = session?.targetZones.toSet() ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ImpactStatus(draft: draft, targetZones: targetZones),
        const SizedBox(height: 20),
        const _SectionLabel('Ligne de fond mordue ?'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _BigToggle(
                label: 'Non',
                icon: Icons.check_rounded,
                selected: !draft.footFault,
                selectedColor: AppColors.success,
                onTap: () => notifier.updateDraft((d) => d.copyWith(footFault: false)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BigToggle(
                label: 'Oui',
                icon: Icons.warning_amber_rounded,
                selected: draft.footFault,
                selectedColor: AppColors.warning,
                onTap: () => notifier.updateDraft((d) => d.copyWith(footFault: true)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Type de service'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ServeTypes.all
              .map(
                (t) => ChoiceChip(
                  label: Text(t.label),
                  avatar: Icon(t.icon, size: 18),
                  selected: draft.serveTypeId == t.id,
                  onSelected: (_) => notifier.updateDraft((d) => d.copyWith(serveTypeId: t.id)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Trajectoire'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _BigToggle(
                label: 'Tendu',
                icon: Icons.flash_on_rounded,
                selected: draft.trajectory == ServeTrajectory.tendue,
                onTap: () => notifier.updateDraft((d) => d.copyWith(trajectory: ServeTrajectory.tendue)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BigToggle(
                label: 'Cloche',
                icon: Icons.arrow_upward_rounded,
                selected: draft.trajectory == ServeTrajectory.cloche,
                onTap: () => notifier.updateDraft((d) => d.copyWith(trajectory: ServeTrajectory.cloche)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Qualité du lancer de balle'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TossQuality.values
              .map(
                (q) => ChoiceChip(
                  label: Text(q.label),
                  selected: draft.tossQuality == q,
                  onSelected: (isSelected) =>
                      notifier.updateDraft((d) => d.copyWith(tossQuality: isSelected ? q : null)),
                ),
              )
              .toList(),
        ),
        if (mode == SessionMode.avecReception && draft.result == ServeResult.inCourt) ...[
          const SizedBox(height: 20),
          const _SectionLabel('Zone d\'arrivée de la réception'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CourtZones.orderedForStats
                .map(
                  (z) => ChoiceChip(
                    label: Text(CourtZones.label(z)),
                    selected: draft.receptionZone == z,
                    onSelected: (_) => notifier.updateDraft((d) => d.copyWith(receptionZone: z)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Réception adverse'),
          const SizedBox(height: 4),
          const Text(
            'Bonne réception : balle haute, vers le milieu de terrain (service facile). '
            'Ace : point direct ou réception ratée (service dangereux).',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReceptionQuality.values
                .map(
                  (q) => ChoiceChip(
                    label: Text(q.shortLabel),
                    selected: draft.receptionQuality == q,
                    onSelected: (_) => notifier.updateDraft((d) => d.copyWith(receptionQuality: q)),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _ImpactStatus extends StatelessWidget {
  final ServeDraft draft;
  final Set<String> targetZones;
  const _ImpactStatus({required this.draft, required this.targetZones});

  @override
  Widget build(BuildContext context) {
    if (draft.result == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.touch_app_rounded, color: AppColors.info),
            SizedBox(width: 10),
            Expanded(child: Text('Touche le terrain à l\'endroit où le ballon est tombé.')),
          ],
        ),
      );
    }
    // Zone visée choisie pour la séance, mais service tombé ailleurs : on
    // affiche ça comme un raté (rouge), même si le service reste bien "IN"
    // dans les statistiques — c'est juste une aide visuelle en direct.
    final missedTargetZone = draft.result == ServeResult.inCourt &&
        targetZones.isNotEmpty &&
        !targetZones.contains(draft.zone);

    final Color color;
    final IconData icon;
    final String text;
    if (missedTargetZone) {
      color = AppColors.error;
      icon = Icons.cancel_rounded;
      text = 'IN — ${draft.zone == 'piscine' ? 'Piscine' : 'Zone ${draft.zone?.replaceAll('zone', '')}'} (hors zone visée)';
    } else {
      switch (draft.result!) {
        case ServeResult.inCourt:
          color = AppColors.success;
          icon = Icons.check_circle_rounded;
          final depthLabel = draft.zone != null ? CourtZones.depthLabel(draft.zone!) : null;
          text = 'IN — ${draft.zone == 'piscine' ? 'Piscine' : 'Zone ${draft.zone?.replaceAll('zone', '')}'}'
              '${depthLabel != null ? ' ($depthLabel)' : ''}';
          break;
        case ServeResult.out:
          color = AppColors.error;
          icon = Icons.cancel_rounded;
          text = 'OUT';
          break;
        case ServeResult.net:
          color = AppColors.warning;
          icon = Icons.block_rounded;
          text = 'FILET';
          break;
      }
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary));
  }
}

class _BigToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;

  const _BigToggle({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.selectedColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withValues(alpha: 0.12) : AppColors.surface,
          border: Border.all(color: selected ? selectedColor : AppColors.border, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? selectedColor : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? selectedColor : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
