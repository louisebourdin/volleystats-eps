import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/court_zone.dart';
import '../models/recommendation.dart';
import '../models/serve_analysis.dart';
import '../models/serve_enums.dart';
import '../models/session.dart';
import '../providers/history_provider.dart';
import '../providers/session_provider.dart';
import '../services/csv_downloader/csv_downloader.dart';
import '../services/csv_export_service.dart';
import '../services/recommendation_engine.dart';
import '../services/statistics_service.dart';
import '../theme/app_colors.dart';
import '../utils/french_date.dart';
import '../utils/responsive.dart';
import '../widgets/court/court_marker.dart';
import '../widgets/court/volley_court_widget.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/statistic_card.dart';
import 'home_screen.dart';
import 'new_session_screen.dart';

/// Bilan de la série (§12-§18) : régularité, précision, variété, carte des
/// impacts, puis une réflexion guidée — c'est à l'élève de construire son
/// propre bilan à partir des stats, pas à l'appli de le faire à sa place.
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
                    final right = _rightColumn(currentSession, analysis, recommendations);
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
                _ActionButtons(session: currentSession),
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
        child: _CountList(
          labels: const ['IN', 'OUT', 'FILET'],
          values: [analysis.inCount, analysis.outCount, analysis.netCount],
        ),
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
          child: _CountList(
            labels: ReceptionQuality.values.map((q) => q.shortLabel).toList(),
            values: ReceptionQuality.values.map((q) => analysis.receptionQualityCounts[q.name] ?? 0).toList(),
          ),
        ),
      ],
      const SizedBox(height: 16),
      StatisticCard(
        title: 'Précision — zones visées',
        icon: Icons.grid_view_rounded,
        subtitle: 'Services courts (2, 3, 4) : ${analysis.shortServeCount} · '
            'Services longs (5, 6, 1) : ${analysis.longServeCount}',
        child: _CountList(
          labels: analysis.zoneCountsOrdered.map((e) => CourtZones.label(e.key)).toList(),
          values: analysis.zoneCountsOrdered.map((e) => e.value).toList(),
        ),
      ),
      const SizedBox(height: 16),
      StatisticCard(
        title: 'Types de service',
        icon: Icons.sports_volleyball_outlined,
        child: _CountList(
          labels: analysis.serveTypeCounts.keys.map(_serveTypeShortLabel).toList(),
          values: analysis.serveTypeCounts.values.toList(),
        ),
      ),
      const SizedBox(height: 16),
      StatisticCard(
        title: 'Trajectoire',
        icon: Icons.show_chart_rounded,
        child: _CountList(
          labels: const ['Tendu', 'Cloche'],
          values: [analysis.fastTrajectoryCount, analysis.slowTrajectoryCount],
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

  List<Widget> _rightColumn(Session session, ServeAnalysis analysis, List<Recommendation> recommendations) {
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
      _StudentReflection(session: session, recommendations: recommendations),
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

/// Liste simple "label : valeur", utilisée à la place de graphiques pour
/// garder les statistiques lisibles directement (§ nouvelle présentation du
/// bilan : les élèves doivent pouvoir lire les chiffres sans interpréter un
/// graphique).
class _CountList extends StatelessWidget {
  final List<String> labels;
  final List<int> values;

  const _CountList({required this.labels, required this.values});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(child: Text(labels[i])),
                Text(
                  '${values[i]}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: values[i] == 0 ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Questions de réflexion guidée (§ nouvelle présentation du bilan). Pas de
/// question sur la réception hors mode "avec réception".
List<String> _reflectionQuestions(Session session) => [
      'Combien de tes services sont tombés dans le terrain sur 10 ? Es-tu satisfait(e) de ce résultat ?',
      'En regardant la carte des impacts et la précision par zone : tes services sont-ils plutôt variés ou '
          'concentrés dans une même zone ?',
      'As-tu eu des fautes de pied ou des services dans le filet ? Qu\'est-ce que ça t\'apprend sur ton geste ?',
      'Entre le service tendu et le service en cloche, lequel te réussit le mieux ? Pourquoi, à ton avis ?',
      if (session.mode == SessionMode.avecReception)
        'Tes services ont-ils mis l\'adversaire en danger (réceptions ratées ou ace) ? Pourquoi ?',
      'Selon toi, quel est ton point fort sur cette série ?',
      'Quel est, selon toi, le point à travailler en priorité pour ta prochaine série ?',
    ];

/// Réflexion guidée : l'élève répond à une question à la fois, à l'aide des
/// statistiques affichées sur l'écran. Les réponses ne sont pas sauvegardées
/// — c'est un support de réflexion, pas une donnée de la série. Une fois
/// toutes les questions passées, l'axe prioritaire de l'appli s'affiche pour
/// comparaison (sans les exercices : ça reste le rôle de l'enseignant).
class _StudentReflection extends StatefulWidget {
  final Session session;
  final List<Recommendation> recommendations;

  const _StudentReflection({required this.session, required this.recommendations});

  @override
  State<_StudentReflection> createState() => _StudentReflectionState();
}

class _StudentReflectionState extends State<_StudentReflection> {
  late final List<String> _questions = _reflectionQuestions(widget.session);
  late final List<TextEditingController> _controllers = [
    for (var i = 0; i < _questions.length; i++) TextEditingController(),
  ];
  int _index = 0;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finished = _index >= _questions.length;
    return StatisticCard(
      title: 'Ton bilan',
      icon: Icons.edit_note_rounded,
      subtitle: finished
          ? 'Voici l\'avis de l\'appli : compare-le avec ta propre réflexion.'
          : 'Question ${_index + 1} / ${_questions.length} — aide-toi des statistiques ci-dessus.',
      child: finished ? _buildResult() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_questions[_index], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, height: 1.35)),
        const SizedBox(height: 12),
        TextField(
          controller: _controllers[_index],
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Écris ta réponse ici...', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (_index > 0)
              OutlinedButton(onPressed: () => setState(() => _index--), child: const Text('Précédent')),
            const Spacer(),
            ElevatedButton(
              onPressed: () => setState(() => _index++),
              child: Text(_index == _questions.length - 1 ? 'Voir l\'avis de l\'appli' : 'Suivant'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in widget.recommendations) ...[
          RecommendationCard(recommendation: r),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => setState(() => _index = 0),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Revoir mes réponses'),
        ),
      ],
    );
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
  final Session session;
  const _ActionButtons({required this.session});

  Future<void> _exportCsv(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final content = CsvExportService.build(session);
      final fileName = CsvExportService.suggestedFileName(session);
      final resultMessage = await downloadCsv(fileName: fileName, content: content);
      messenger.showSnackBar(SnackBar(content: Text(resultMessage)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Échec de l\'export CSV.')));
    }
  }

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
        OutlinedButton.icon(
          onPressed: () => _exportCsv(context),
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Exporter en CSV'),
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
