import 'package:flutter/material.dart';

import '../../models/court_zone.dart';
import '../../models/serve_enums.dart';
import 'court_geometry.dart';
import 'court_marker.dart';
import 'volley_court_painter.dart';

/// Terrain de volley interactif (vu du dessus), CustomPainter + GestureDetector.
/// Fonctionne au tactile (smartphone/tablette) comme à la souris (desktop/web).
/// Les coordonnées d'appui sont normalisées 0..1 : le terrain se redimensionne
/// sans jamais perdre la position des impacts (cahier des charges §29).
class VolleyCourtWidget extends StatelessWidget {
  final List<CourtMarker> markers;
  final void Function(TapZoneResult result, double x, double y)? onTap;

  /// Zone actuellement sélectionnée (saisie en cours) : mise en évidence
  /// visuellement en plus du marqueur (§9 — "elle doit être mise en évidence").
  final String? highlightZone;

  /// Zone(s) "à travailler" pour la séance : restent visuellement marquées
  /// pendant toute la saisie des 10 services, en plus de [highlightZone].
  final Set<String> targetZones;

  /// Mode sélection : au lieu d'enregistrer un impact, un tap sur une des 6
  /// zones (Piscine/OUT/FILET ignorés) bascule son appartenance à
  /// [targetZones] via [onZoneToggle]. Utilisé sur l'écran "Nouvelle série".
  final bool zonePickerMode;
  final ValueChanged<String>? onZoneToggle;

  const VolleyCourtWidget({
    super.key,
    this.markers = const [],
    this.onTap,
    this.highlightZone,
    this.targetZones = const {},
    this.zonePickerMode = false,
    this.onZoneToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.74,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          void Function(TapUpDetails)? handleTap;
          if (zonePickerMode && onZoneToggle != null) {
            handleTap = (details) {
              final local = details.localPosition;
              final x = (local.dx / size.width).clamp(0.0, 1.0);
              final y = (local.dy / size.height).clamp(0.0, 1.0);
              final result = CourtGeometry.resultForPoint(Offset(x, y));
              if (result.result == ServeResult.inCourt &&
                  result.zone != null &&
                  result.zone != CourtZones.piscine) {
                onZoneToggle!(result.zone!);
              }
            };
          } else if (onTap != null) {
            handleTap = (details) {
              final local = details.localPosition;
              final x = (local.dx / size.width).clamp(0.0, 1.0);
              final y = (local.dy / size.height).clamp(0.0, 1.0);
              final result = CourtGeometry.resultForPoint(Offset(x, y));
              onTap!(result, x, y);
            };
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: handleTap,
            child: Semantics(
              label: zonePickerMode
                  ? 'Sélection des zones à travailler. Touchez une ou plusieurs zones du terrain.'
                  : 'Terrain de volley interactif. Touchez l\'endroit où le ballon est tombé.',
              child: CustomPaint(
                size: size,
                painter: VolleyCourtPainter(
                  markers: markers,
                  highlightZone: highlightZone,
                  targetZones: targetZones,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
