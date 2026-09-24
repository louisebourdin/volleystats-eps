import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/court_zone.dart';
import '../models/recommendation.dart';
import '../models/serve_analysis.dart';
import '../models/serve_enums.dart';
import '../models/session.dart';
import '../providers/history_provider.dart';
import '../providers/session_provider.dart';
import '../services/recommendation_engine.dart';
import '../services/statistics_service.dart';
import '../theme/app_colors.dart';
import '../utils/french_date.dart';
import '../utils/responsive.dart';
import '../widgets/court/court_marker.dart';
import '../widgets/court/volley_court_widget.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/result_charts.dart';
import '../widgets/statistic_card.dart';
import 'home_screen.dart';
import 'new_session_screen.dart';

/// Bilan de la série (§12-§18) : régularité, précision, variété, carte des
/// impacts, et conseils personnalisés — jamais uniquement un score.
class ResultsScreen extends ConsumerWidget {
  /// Si fourni (relecture depuis l'historique), on affiche cette série au
  /// lieu de celle en cours dans [sessionProvider].
  final Session? session;

  const ResultsScreen({super.key, this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSession = session ?? ref.watch(sessionProvider).session;
    if (currentSession == null || !currentSession.isComplete) {
      return const Scaffold(body: Center(child: Text('Aucun bilan disponible.')));
    }

    final analysis = StatisticsService.analyze(currentSession);
    final recommendations = RecommendationEngine.generate(analysis);
    final strengths = StatisticsService.strengths(analysis);

    final history = ref.watch(historyProvider);
    final sameStudentSessions = history
        .where((s) => s.student.name.toLowerCase() == currentSession.student.name.toLowerCase())
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final idx = sameStudentSessions.indexWhere((s) => s.id == currentSession.id);
    final hasComparison = idx > 0;
    final comparison =
        hasComparison ? StatisticsService.compare(previous: sameStudentSessions[idx - 1], current: currentSession) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Bilan de la série')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: MaxWidthCenter(
            maxWidth: 1200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(session: currentSession, analysis: analysis, comparison: comparison),
                const SizedBox(height: 20),
                ResponsiveBuilder(
                  builder: (context, size, constraints) {
                    final left = _leftColumn(currentSession, analysis);
                    final right = _rightColumn(context, currentSession, analysis, recommendations, strengths);
                    if (size == ScreenSize.mobile) {
                      return Column(children: [...left, const SizedBox(height: 16), ...right]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Column(children: left)),
                        const SizedBox(width: 24),
                        Expanded(child: Column(children: right)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                _ActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _leftColumn(Session session, ServeAnalysis analysis) {
    return [
      StatisticCard(
        title: 'Régularité',
        icon: Icons.track_changes_rounded,
        subtitle: 'Faute de pied : ${analysis.footFaultCount} / ${analysis.total}',
        child: ResultPieChart(inCount: analysis.inCount, outCount: analysis.outCount, netCount: analysis.netCount),
      ),
      if (session.hasTargetZones) ...[
        const SizedBox(height: 16),
        _TargetZoneCard(session: session),
      ],
      if (session.mode == SessionMode.avecReception) ...[
        const SizedBox(height: 16),
        StatisticCard(
          title: 'Efficacité au service — danger provoqué',
          icon: Icons.warning_amber_rounded,
          subtitle: analysis.receptionRecordedCount == 0
              ? 'Aucune réception relevée sur cette série.'
              : '${analysis.dangerousServeCount} / ${analysis.receptionRecordedCount} services ont mis '
                  'l\'adversaire en danger (${analysis.dangerousServeRate.round()} %).',
          child: CategoryBarChart(
            labels: ReceptionQuality.values.map((q) => q.shortLabel).toList(),
            values: ReceptionQuality.values.map((q) => analysis.receptionQualityCounts[q.name] ?? 0).toList(),
            color: AppColors.warning,
          ),
        ),
        const SizedBox(height: 16),
        StatisticCard(
          title: 'Zone d\'arrivée des réceptions',
          icon: Icons.grid_view_rounded,
          child: CategoryBarChart(
            labels: analysis.receptionZoneCountsOrdered.map((e) => CourtZones.shortLabel(e.key)).toList(),
            values: analysis.receptionZoneCountsOrdered.map((e) => e.value).toList(),
            color: AppColors.accent,
          ),
        ),
      ],
      const SizedBox(height: 16),
      StatisticCard(
        title: 'Précision — zones visées',
        icon: Icons.grid_view_rounded,
        subtitle: 'Services courts (2, 3, 4) : ${analysis.shortServeCount} · '
            'Services longs (5, 6, 1) : ${analysis.longServeCount}',
        child: CategoryBarChart(
          labels: analysis.zoneCountsOrdered.map((e) => CourtZones.shortLabel(e.key)).toList(),
          values: analysis.zoneCountsOrdered.map((e) => e.value).toList(),
          color: AppColors.info,
        ),
      ),
      const SizedBox(height: 16),
      StatisticCard(
        title: 'Types de service',
        icon: Icons.sports_volleyball_outlined,
        child: CategoryBarChart(
          labels: analysis.serveTypeCounts.keys.map(_serveTypeShortLabel).toList(),
          values: analysis.serveTypeCounts.values.toList(),
          color: AppColors.accent,
        ),
      ),
      const SizedBox(height: 16),
      StatisticCard(
        title: 'Trajectoire',
        icon: Icons.show_chart_rounded,
        child: CategoryBarChart(
          labels: const ['Tendu', 'Cloche'],
          values: [analysis.fastTrajectoryCount, analysis.slowTrajectoryCount],
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 16),
      StatisticCard(
        title: 'Variété',
        icon: Icons.scatter_plot_rounded,
        child: Row(
          children: [
            Icon(
              analysis.varietyLevel == VarietyLevel.elevee
                  ? Icons.sentiment_very_satisfied_rounded
                  : analysis.varietyLevel == VarietyLevel.moyenne
                      ? Icons.sentiment_neutral_rounded
                      : Icons.sentiment_dissatisfied_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${analysis.varietyLevel.label} — ${analysis.distinctZonesUsed} zone(s) différente(s) utilisée(s).',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _rightColumn(
    BuildContext context,
    Session session,
    ServeAnalysis analysis,
    List<Recommendation> recommendations,
    List<String> strengths,
  ) {
    final markers = session.serves.map((s) {
      final Color color;
      switch (s.result) {
        case ServeResult.inCourt:
          color = AppColors.success;
          break;
        case ServeResult.out:
          color = AppColors.error;
          break;
        case ServeResult.net:
          color = AppColors.warning;
          break;
      }
      return CourtMarker(x: s.positionX, y: s.positionY, color: color, label: '${s.number}');
    }).toList();

    return [
      StatisticCard(
        title: 'Carte des 10 impacts',
        icon: Icons.map_outlined,
        subtitle: 'Vert = IN · Rouge = OUT · Orange = FILET',
        child: VolleyCourtWidget(markers: markers),
      ),
      const SizedBox(height: 16),
      StatisticCard(
        title: 'Mon analyse',
        icon: Icons.insights_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1 — Mon résultat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 6),
            Text('${analysis.inCount} / ${analysis.total} IN — ${analysis.successRatePercent.round()} % de réussite'),
            const SizedBox(height: 16),
            const Text('2 — Ce que je fais bien', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 6),
            ...strengths.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(child: Text(s)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text('3 & 4 — Mon axe prioritaire et mes exercices', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      const SizedBox(height: 10),
      for (final r in recommendations) ...[
        RecommendationCard(recommendation: r),
        const SizedBox(height: 12),
      ],
    ];
  }

  String _serveTypeShortLabel(String id) {
    switch (id) {
      case 'cuillere':
        return 'Cuillère';
      case 'tennis':
        return 'Tennis';
      case 'flottant':
        return 'Flottant';
      case 'smashe':
        return 'Smashé';
      default:
        return id;
    }
  }
}

/// Bilan spécifique à la ou aux zones que l'élève avait choisi de travailler
/// avant de démarrer la série (§ nouvelle fonctionnalité : objectif de zone).
class _TargetZoneCard extends StatelessWidget {
  final Session session;

  const _TargetZoneCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final zoneLabels = (session.targetZones.toList()..sort()).map(CourtZones.label).join(', ');
    final hits = session.serves
        .where((s) => s.result == ServeResult.inCourt && session.targetZones.contains(s.zone))
        .length;
    final total = session.serves.length;
    final pct = total == 0 ? 0 : (hits / total * 100).round();

    return StatisticCard(
      title: 'Objectif de la séance',
      icon: Icons.track_changes_rounded,
      subtitle: 'Zone(s) visée(s) : $zoneLabels',
      child: Row(
        children: [
          Icon(
            hits >= total / 2 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: hits >= total / 2 ? AppColors.success : AppColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$hits / $total services sont tombés dans la zone visée ($pct %).',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Session session;
  final ServeAnalysis analysis;
  final SessionComparison? comparison;

  const _Header({required this.session, required this.analysis, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final pct = analysis.successRatePercent.round();
    final color = pct >= 70 ? AppColors.success : (pct >= 40 ? AppColors.warning : AppColors.error);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${session.student.name} · ${formatFrenchDate(session.date)}',
              style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 10,
              children: [
                Text(
                  '${analysis.inCount} / ${analysis.total} services réussis',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text('$pct % de réussite', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            if (comparison != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _DeltaChip(
                    value: comparison!.successRateDelta,
                    suffix: '% de réussite',
                    icon: Icons.percent_rounded,
                  ),
                  _DeltaChip(
                    value: comparison!.zonesDelta.toDouble(),
                    suffix: 'zone(s) maîtrisée(s)',
                    icon: Icons.grid_view_rounded,
                    isInt: true,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final double value;
  final String suffix;
  final IconData icon;
  final bool isInt;

  const _DeltaChip({required this.value, required this.suffix, required this.icon, this.isInt = false});

  @override
  Widget build(BuildContext context) {
    final positive = value >= 0;
    final color = positive ? AppColors.success : AppColors.error;
    final display = isInt ? value.round().toString() : value.round().toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: color, size: 18),
          const SizedBox(width: 6),
          Text('${positive ? '+' : ''}$display $suffix', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const NewSessionScreen()),
              (route) => route.isFirst,
            );
          },
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Nouvelle série'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
          },
          icon: const Icon(Icons.home_outlined),
          label: const Text('Retour à l\'accueil'),
        ),
      ],
    );
  }
}
