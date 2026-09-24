import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/court_zone.dart';
import '../models/serve_enums.dart';
import '../models/session.dart';
import '../models/student.dart';
import '../providers/session_provider.dart';
import '../theme/app_colors.dart';
import '../utils/french_date.dart';
import '../utils/responsive.dart';
import '../widgets/court/volley_court_widget.dart';
import 'serve_screen.dart';

class NewSessionScreen extends ConsumerStatefulWidget {
  const NewSessionScreen({super.key});

  @override
  ConsumerState<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends ConsumerState<NewSessionScreen> {
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  DominantHand _hand = DominantHand.droitier;
  String _mainServeTypeId = ServeTypes.tennis.id;
  final Set<String> _targetZones = {};
  SessionMode _mode = SessionMode.sansReception;
  final Set<String> _receptionZones = {};

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    super.dispose();
  }

  bool get _canStart => _nameController.text.trim().isNotEmpty;

  void _start() {
    final student = Student(
      name: _nameController.text.trim(),
      className: _classController.text.trim(),
      dominantHand: _hand,
      mainServeTypeId: _mainServeTypeId,
    );
    ref.read(sessionProvider.notifier).startSession(
          student,
          targetZones: _targetZones.toList(),
          mode: _mode,
          receptionZones: _receptionZones.toList(),
        );
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ServeScreen()));
  }

  void _toggleZone(String zoneId) {
    setState(() {
      if (_targetZones.contains(zoneId)) {
        _targetZones.remove(zoneId);
      } else {
        _targetZones.add(zoneId);
      }
    });
  }

  void _toggleReceptionZone(String zoneId) {
    setState(() {
      if (_receptionZones.contains(zoneId)) {
        _receptionZones.remove(zoneId);
      } else {
        _receptionZones.add(zoneId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = formatFrenchDate(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle série')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: MaxWidthCenter(
            maxWidth: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Qui réalise les services ?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(dateLabel, style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Prénom ou pseudonyme', prefixIcon: Icon(Icons.person_outline_rounded)),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _classController,
                  decoration: const InputDecoration(labelText: 'Classe', prefixIcon: Icon(Icons.groups_outlined)),
                ),
                const SizedBox(height: 24),
                const Text('Main dominante', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SegmentedButton<DominantHand>(
                  segments: const [
                    ButtonSegment(value: DominantHand.droitier, label: Text('Droitier'), icon: Icon(Icons.back_hand_outlined)),
                    ButtonSegment(value: DominantHand.gaucher, label: Text('Gaucher'), icon: Icon(Icons.front_hand_outlined)),
                  ],
                  selected: {_hand},
                  onSelectionChanged: (s) => setState(() => _hand = s.first),
                ),
                const SizedBox(height: 24),
                const Text('Type de service principal', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ServeTypes.all
                      .map(
                        (t) => ChoiceChip(
                          label: Text(t.label),
                          avatar: Icon(t.icon, size: 18),
                          selected: _mainServeTypeId == t.id,
                          onSelected: (_) => setState(() => _mainServeTypeId = t.id),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                const Text('Zone(s) à travailler (facultatif)', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                  'Touche une ou plusieurs zones du terrain pour que l\'élève s\'entraîne à viser précisément '
                  'ces zones pendant la série. Laisse vide pour un entraînement libre.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: VolleyCourtWidget(
                    zonePickerMode: true,
                    targetZones: _targetZones,
                    onZoneToggle: _toggleZone,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _targetZones.isEmpty
                            ? 'Entraînement libre (toutes les zones)'
                            : 'Zone(s) choisie(s) : ${(_targetZones.toList()..sort()).map(CourtZones.label).join(', ')}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_targetZones.isNotEmpty)
                      TextButton(
                        // Le thème par défaut des TextButton force une largeur minimale
                        // infinie (pensée pour les gros boutons pleine largeur) : on la
                        // réinitialise ici puisque ce bouton est inline, à côté du texte.
                        style: TextButton.styleFrom(minimumSize: const Size(64, 36)),
                        onPressed: () => setState(_targetZones.clear),
                        child: const Text('Tout effacer'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Mode d\'analyse', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                  'En mode "avec réception", tu notes en plus, pour chaque service réussi, où repart la '
                  'réception adverse — pour mesurer le danger provoqué par le service.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SegmentedButton<SessionMode>(
                  segments: const [
                    ButtonSegment(
                      value: SessionMode.sansReception,
                      label: Text('Sans réception'),
                      icon: Icon(Icons.sports_volleyball_outlined),
                    ),
                    ButtonSegment(
                      value: SessionMode.avecReception,
                      label: Text('Avec réception'),
                      icon: Icon(Icons.groups_2_outlined),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                if (_mode == SessionMode.avecReception) ...[
                  const SizedBox(height: 20),
                  const Text('Postes des réceptionneurs (facultatif)', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text(
                    'Touche les postes (1 à 6) où se trouvent tes réceptionneurs. Purement informatif : '
                    'affiché pendant la saisie, sans effet sur les statistiques.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: VolleyCourtWidget(
                      zonePickerMode: true,
                      targetZones: _receptionZones,
                      onZoneToggle: _toggleReceptionZone,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _receptionZones.isEmpty
                        ? 'Aucun poste renseigné'
                        : '${_receptionZones.length} réceptionneur(s) : '
                            '${(_receptionZones.toList()..sort()).map(CourtZones.label).join(', ')}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _canStart ? _start : null,
                  child: const Text('Commencer les 10 services'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
