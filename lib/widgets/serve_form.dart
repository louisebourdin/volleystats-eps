import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/court_zone.dart';
import '../models/serve_draft.dart';
import '../models/serve_enums.dart';
import '../models/session.dart';
import '../providers/session_provider.dart';
import '../theme/app_colors.dart';

/// Formulaire rapide d'un service : quelques choix à toucher, rien de plus.
/// Les champs facultatifs (§10) sont repliés sous "Plus de détails".
class ServeForm extends ConsumerWidget {
  const ServeForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(sessionProvider).draft;
    final notifier = ref.read(sessionProvider.notifier);
    final mode = ref.watch(sessionProvider).session?.mode ?? SessionMode.sansReception;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ImpactStatus(draft: draft),
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
        if (mode == SessionMode.avecReception && draft.result == ServeResult.inCourt) ...[
          const SizedBox(height: 20),
          const _SectionLabel('Réception adverse'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReceptionQuality.values
                .map(
                  (q) => ChoiceChip(
                    label: Text(q.label),
                    selected: draft.receptionQuality == q,
                    onSelected: (_) => notifier.updateDraft((d) => d.copyWith(receptionQuality: q)),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Plus de détails (facultatif)', style: TextStyle(fontWeight: FontWeight.w700)),
            childrenPadding: const EdgeInsets.only(bottom: 12),
            children: [
              _OptionalEnumSection<TossQuality>(
                label: 'Qualité du lancer de balle (si hors service cuillère)',
                values: TossQuality.values,
                labelOf: (v) => v.label,
                selected: draft.tossQuality,
                onSelected: (v) => notifier.updateDraft((d) => d.copyWith(tossQuality: v)),
              ),
              _OptionalEnumSection<ContactQuality>(
                label: 'Qualité du contact',
                values: ContactQuality.values,
                labelOf: (v) => v.label,
                selected: draft.contactQuality,
                onSelected: (v) => notifier.updateDraft((d) => d.copyWith(contactQuality: v)),
              ),
              _OptionalEnumSection<ServePower>(
                label: 'Puissance',
                values: ServePower.values,
                labelOf: (v) => v.label,
                selected: draft.power,
                onSelected: (v) => notifier.updateDraft((d) => d.copyWith(power: v)),
              ),
              _OptionalEnumSection<ServeIntention>(
                label: 'Intention',
                values: ServeIntention.values,
                labelOf: (v) => v.label,
                selected: draft.intention,
                onSelected: (v) => notifier.updateDraft((d) => d.copyWith(intention: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImpactStatus extends StatelessWidget {
  final ServeDraft draft;
  const _ImpactStatus({required this.draft});

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
    final Color color;
    final IconData icon;
    final String text;
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

class _OptionalEnumSection<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final String Function(T) labelOf;
  final T? selected;
  final ValueChanged<T?> onSelected;

  const _OptionalEnumSection({
    required this.label,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (v) => ChoiceChip(
                    label: Text(labelOf(v)),
                    selected: selected == v,
                    onSelected: (isSelected) => onSelected(isSelected ? v : null),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
