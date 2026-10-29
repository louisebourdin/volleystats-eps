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

  /// Demi-largeur (fraction du terrain) de la bande autour d'une ligne de
  /// séparation entre deux zones voisines, dans laquelle un appui est
  /// considéré comme "sur la ligne" plutôt que dans l'une ou l'autre zone.
  static const double interZoneTolerance = 0.015;

  /// Tolérance (fraction du terrain) sur les lignes de côté et de fond :
  /// comme en vrai volley, une balle qui touche la ligne reste IN — un appui
  /// juste à l'extérieur de ces lignes compte donc encore comme dans le
  /// terrain. Ne s'applique jamais à la ligne du filet (déjà sa propre bande).
  static const double outerLineTolerance = 0.015;

  /// Zone "inter zone" si [x] tombe sur l'une des deux lignes verticales qui
  /// séparent les zones d'une même rangée (jamais la ligne avant/arrière).
  static String? _interZoneForColumnBoundary(int row, double x) {
    final leftBoundary = courtLeft + colWidth;
    final rightBoundary = courtLeft + 2 * colWidth;
    if ((x - leftBoundary).abs() <= interZoneTolerance) {
      return row == 0 ? CourtZones.interZone34 : CourtZones.interZone56;
    }
    if ((x - rightBoundary).abs() <= interZoneTolerance) {
      return row == 0 ? CourtZones.interZone23 : CourtZones.interZone16;
    }
    return null;
  }

  /// Les deux zones voisines que chaque "inter zone" chevauche (voir
  /// [CourtZones.interZones]).
  static const Map<String, (String, String)> _interZoneComponents = {
    CourtZones.interZone34: (CourtZones.zone3, CourtZones.zone4),
    CourtZones.interZone23: (CourtZones.zone2, CourtZones.zone3),
    CourtZones.interZone56: (CourtZones.zone5, CourtZones.zone6),
    CourtZones.interZone16: (CourtZones.zone1, CourtZones.zone6),
  };

  /// Rectangle (fractions 0..1) occupé par une zone donnée — utile pour
  /// dessiner ses bordures et centrer son numéro. Pour une "inter zone", le
  /// rectangle couvre les deux zones voisines qu'elle chevauche (pas de
  /// rectangle propre, puisque c'est justement la ligne entre les deux).
  static Rect rectForZone(String zoneId) {
    if (zoneId == CourtZones.piscine) {
      return Rect.fromLTRB(
        midX - piscineHalfWidth,
        midY - piscineHalfHeight,
        midX + piscineHalfWidth,
        midY + piscineHalfHeight,
      );
    }
    final pair = _interZoneComponents[zoneId];
    if (pair != null) {
      return rectForZone(pair.$1).expandToInclude(rectForZone(pair.$2));
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
  /// [includeInterZones] détecte les appuis sur une ligne entre deux zones
  /// voisines (voir [CourtZones.interZones]) ; désactivé en mode sélection
  /// de zone (l'élève y choisit toujours une zone précise, jamais une ligne).
  static TapZoneResult resultForPoint(Offset p, {bool includeInterZones = true}) {
    final x = p.dx;
    final y = p.dy;

    // Bande de filet.
    final net = netRect;
    if (x >= net.left && x <= net.right && y >= net.top && y <= net.bottom) {
      return TapZoneResult(result: ServeResult.net, zone: null, direction: directionForX(x));
    }

    // Intérieur du terrain — avec une tolérance sur les lignes de côté et de
    // fond (jamais sur la ligne du filet, déjà couverte par sa propre bande).
    final court = courtRect;
    final touchesCourt = x >= court.left - outerLineTolerance &&
        x <= court.right + outerLineTolerance &&
        y >= court.top &&
        y <= court.bottom + outerLineTolerance;
    if (touchesCourt) {
      // Un appui juste hors des lignes (toléré ci-dessus) se rattache à la
      // zone la plus proche : on ramène le point dans les bornes exactes
      // avant de déterminer piscine / inter zone / zone.
      final cx = x.clamp(court.left, court.right);
      final cy = y.clamp(court.top, court.bottom);
      // Zone "Piscine" en incrustation centrale : prioritaire sur la grille.
      if ((cx - midX).abs() <= piscineHalfWidth && (cy - midY).abs() <= piscineHalfHeight) {
        return TapZoneResult(result: ServeResult.inCourt, zone: CourtZones.piscine, direction: directionForX(cx));
      }
      final row = cy < midY ? 0 : 1;
      if (includeInterZones) {
        final interZone = _interZoneForColumnBoundary(row, cx);
        if (interZone != null) {
          return TapZoneResult(result: ServeResult.inCourt, zone: interZone, direction: directionForX(cx));
        }
      }
      final col = (((cx - courtLeft) / colWidth).floor()).clamp(0, 2);
      final zone = _grid[row][col];
      return TapZoneResult(result: ServeResult.inCourt, zone: zone, direction: directionForX(cx));
    }

    // Tout le reste (avant le filet, au-delà des lignes de fond/côté) = OUT.
    return TapZoneResult(result: ServeResult.out, zone: null, direction: directionForX(x));
  }
}
