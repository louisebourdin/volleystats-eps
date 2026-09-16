import 'dart:ui';

import '../../models/court_zone.dart';
import '../../models/serve_enums.dart';

/// Résultat d'un appui sur le terrain : tout ce qu'il faut pour remplir
/// automatiquement résultat / zone / direction du service.
class TapZoneResult {
  final ServeResult result;
  final String? zone;
  final ServeDirection direction;

  const TapZoneResult({required this.result, required this.zone, required this.direction});
}

/// Géométrie du terrain interactif, exprimée en coordonnées normalisées
/// (0..1 sur toute la largeur/hauteur du widget). Utilisée à la fois par le
/// [CustomPainter] (pour dessiner) et par le détecteur de gestes (pour
/// déterminer la zone touchée) : une seule source de vérité, jamais de
/// désynchronisation entre affichage et détection.
class CourtGeometry {
  CourtGeometry._();

  // Bande du filet.
  static const double netY = 0.11;
  static const double netHalfThickness = 0.025;

  // Rectangle du terrain adverse (les 6 zones).
  static const double courtLeft = 0.14;
  static const double courtRight = 0.86;
  static const double courtTop = netY + netHalfThickness;
  static const double courtBottom = 0.90;

  // Zone "Piscine" : rectangle central, en incrustation.
  static const double piscineHalfWidth = 0.135;
  static const double piscineHalfHeight = 0.11;

  static double get midX => (courtLeft + courtRight) / 2;
  static double get midY => (courtTop + courtBottom) / 2;
  static double get colWidth => (courtRight - courtLeft) / 3;
  static double get rowHeight => (courtBottom - courtTop) / 2;

  static const Map<String, List<int>> _zoneRowCol = {
    CourtZones.zone4: [0, 0],
    CourtZones.zone3: [0, 1],
    CourtZones.zone2: [0, 2],
    CourtZones.zone5: [1, 0],
    CourtZones.zone6: [1, 1],
    CourtZones.zone1: [1, 2],
  };

  static const List<List<String>> _grid = [
    [CourtZones.zone4, CourtZones.zone3, CourtZones.zone2],
    [CourtZones.zone5, CourtZones.zone6, CourtZones.zone1],
  ];

  /// Rectangle (fractions 0..1) occupé par une zone donnée — utile pour
  /// dessiner ses bordures et centrer son numéro.
  static Rect rectForZone(String zoneId) {
    if (zoneId == CourtZones.piscine) {
      return Rect.fromLTRB(
        midX - piscineHalfWidth,
        midY - piscineHalfHeight,
        midX + piscineHalfWidth,
        midY + piscineHalfHeight,
      );
    }
    final rc = _zoneRowCol[zoneId]!;
    final left = courtLeft + rc[1] * colWidth;
    final top = courtTop + rc[0] * rowHeight;
    return Rect.fromLTWH(left, top, colWidth, rowHeight);
  }

  static Rect get netRect => Rect.fromLTRB(courtLeft, netY - netHalfThickness, courtRight, netY + netHalfThickness);

  static Rect get courtRect => Rect.fromLTRB(courtLeft, courtTop, courtRight, courtBottom);

  static ServeDirection directionForX(double x) {
    if (x < courtLeft + colWidth) return ServeDirection.gauche;
    if (x > courtRight - colWidth) return ServeDirection.droite;
    return ServeDirection.centre;
  }

  /// Détermine résultat / zone / direction à partir d'un point normalisé.
  /// Le point peut légèrement sortir de [0, 1] (zone OUT autour du terrain).
  static TapZoneResult resultForPoint(Offset p) {
    final x = p.dx;
    final y = p.dy;

    // Bande de filet.
    final net = netRect;
    if (x >= net.left && x <= net.right && y >= net.top && y <= net.bottom) {
      return TapZoneResult(result: ServeResult.net, zone: null, direction: directionForX(x));
    }

    // Intérieur du terrain.
    final court = courtRect;
    if (x >= court.left && x <= court.right && y >= court.top && y <= court.bottom) {
      // Zone "Piscine" en incrustation centrale : prioritaire sur la grille.
      if ((x - midX).abs() <= piscineHalfWidth && (y - midY).abs() <= piscineHalfHeight) {
        return const TapZoneResult(
          result: ServeResult.inCourt,
          zone: CourtZones.piscine,
          direction: ServeDirection.centre,
        );
      }
      final col = (((x - courtLeft) / colWidth).floor()).clamp(0, 2);
      final row = y < midY ? 0 : 1;
      final zone = _grid[row][col];
      return TapZoneResult(result: ServeResult.inCourt, zone: zone, direction: directionForX(x));
    }

    // Tout le reste (avant le filet, au-delà des lignes de fond/côté) = OUT.
    return TapZoneResult(result: ServeResult.out, zone: null, direction: directionForX(x));
  }
}
