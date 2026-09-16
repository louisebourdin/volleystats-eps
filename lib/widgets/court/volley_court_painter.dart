import 'package:flutter/material.dart';

import '../../models/court_zone.dart';
import '../../theme/app_colors.dart';
import 'court_geometry.dart';
import 'court_marker.dart';

class VolleyCourtPainter extends CustomPainter {
  final List<CourtMarker> markers;
  final bool showZoneLabels;
  final String? highlightZone;
  final Set<String> targetZones;

  VolleyCourtPainter({
    required this.markers,
    this.showZoneLabels = true,
    this.highlightZone,
    this.targetZones = const {},
  });

  Offset _p(Size size, double fx, double fy) => Offset(fx * size.width, fy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));
    canvas.save();
    canvas.clipRRect(outer);

    // Zone "out" (fond général autour du terrain).
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.outZone);

    // Terrain (les 6 zones).
    final courtRect = CourtGeometry.courtRect;
    final courtRectPx = Rect.fromPoints(
      _p(size, courtRect.left, courtRect.top),
      _p(size, courtRect.right, courtRect.bottom),
    );
    canvas.drawRect(courtRectPx, Paint()..color = AppColors.courtFloor);

    // Lignes de séparation des zones (grille 2x3).
    final linePaint = Paint()
      ..color = AppColors.courtLine.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final midYpx = (courtRectPx.top + courtRectPx.bottom) / 2;
    final col1 = courtRectPx.left + (courtRectPx.width / 3);
    final col2 = courtRectPx.left + (courtRectPx.width * 2 / 3);
    canvas.drawLine(Offset(col1, courtRectPx.top), Offset(col1, courtRectPx.bottom), linePaint);
    canvas.drawLine(Offset(col2, courtRectPx.top), Offset(col2, courtRectPx.bottom), linePaint);
    canvas.drawLine(Offset(courtRectPx.left, midYpx), Offset(courtRectPx.right, midYpx), linePaint);

    // Bordure du terrain (ligne de fond / lignes de côté).
    canvas.drawRect(
      courtRectPx,
      Paint()
        ..color = AppColors.courtLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    // Zone(s) "à travailler" pour la séance : marquage persistant, distinct
    // de la sélection courante (couleur ET pictogramme cible, jamais la
    // couleur seule — §26).
    for (final zoneId in targetZones) {
      if (zoneId == CourtZones.piscine) continue;
      final tr = CourtGeometry.rectForZone(zoneId);
      final trPx = Rect.fromPoints(_p(size, tr.left, tr.top), _p(size, tr.right, tr.bottom));
      canvas.drawRect(trPx, Paint()..color = AppColors.accent.withValues(alpha: 0.16));
      canvas.drawRect(
        trPx,
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      final badgeCenter = Offset(trPx.right - 16, trPx.top + 16);
      final badgeRadius = (size.width * 0.028).clamp(7, 11).toDouble();
      canvas.drawCircle(badgeCenter, badgeRadius + 2, Paint()..color = Colors.white);
      canvas.drawCircle(badgeCenter, badgeRadius, Paint()..color = AppColors.accent);
      canvas.drawCircle(badgeCenter, badgeRadius * 0.45, Paint()..color = Colors.white);
    }

    // Mise en évidence de la zone sélectionnée (§9).
    if (highlightZone != null && highlightZone != CourtZones.piscine) {
      final hr = CourtGeometry.rectForZone(highlightZone!);
      final hrPx = Rect.fromPoints(_p(size, hr.left, hr.top), _p(size, hr.right, hr.bottom));
      canvas.drawRect(hrPx, Paint()..color = AppColors.primary.withValues(alpha: 0.22));
      canvas.drawRect(
        hrPx,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    // Numéros de zone.
    if (showZoneLabels) {
      for (final zoneId in [
        CourtZones.zone1,
        CourtZones.zone2,
        CourtZones.zone3,
        CourtZones.zone4,
        CourtZones.zone5,
        CourtZones.zone6,
      ]) {
        final r = CourtGeometry.rectForZone(zoneId);
        final centerPx = _p(size, (r.left + r.right) / 2, (r.top + r.bottom) / 2);
        _drawText(
          canvas,
          CourtZones.shortLabel(zoneId),
          centerPx,
          color: AppColors.courtLine.withValues(alpha: 0.85),
          fontSize: (size.width * 0.075).clamp(14, 26),
          bold: true,
        );
      }
    }

    // Zone piscine (incrustation centrale).
    final piscineRect = CourtGeometry.rectForZone(CourtZones.piscine);
    final piscineRectPx = Rect.fromPoints(
      _p(size, piscineRect.left, piscineRect.top),
      _p(size, piscineRect.right, piscineRect.bottom),
    );
    final piscineHighlighted = highlightZone == CourtZones.piscine;
    final piscineRRect = RRect.fromRectAndRadius(piscineRectPx, const Radius.circular(12));
    canvas.drawRRect(
      piscineRRect,
      Paint()..color = piscineHighlighted ? AppColors.primary.withValues(alpha: 0.35) : AppColors.piscineFill.withValues(alpha: 0.9),
    );
    canvas.drawRRect(
      piscineRRect,
      Paint()
        ..color = piscineHighlighted ? AppColors.primary : AppColors.primaryDark.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = piscineHighlighted ? 2.5 : 1.6,
    );
    if (showZoneLabels) {
      _drawText(
        canvas,
        'Piscine',
        piscineRectPx.center,
        color: AppColors.primaryDark,
        fontSize: (size.width * 0.05).clamp(11, 16),
        bold: true,
      );
    }

    // Filet.
    final netRect = CourtGeometry.netRect;
    final netRectPx = Rect.fromPoints(_p(size, netRect.left, netRect.top), _p(size, netRect.right, netRect.bottom));
    canvas.drawRect(netRectPx, Paint()..color = AppColors.netColor);
    for (double fx = 0; fx <= 1; fx += 1 / 22) {
      final x = netRectPx.left + fx * netRectPx.width;
      canvas.drawLine(Offset(x, netRectPx.top), Offset(x, netRectPx.bottom), Paint()..color = Colors.white.withValues(alpha: 0.35)..strokeWidth = 1);
    }
    _drawText(canvas, 'FILET', Offset(netRectPx.center.dx, netRectPx.center.dy),
        color: Colors.white, fontSize: (size.width * 0.045).clamp(11, 15), bold: true);

    // Étiquette "OUT" discrète en bas.
    _drawText(
      canvas,
      'OUT',
      Offset(size.width / 2, size.height * 0.965),
      color: AppColors.error.withValues(alpha: 0.55),
      fontSize: (size.width * 0.04).clamp(10, 13),
      bold: true,
    );

    // Impacts.
    for (var i = 0; i < markers.length; i++) {
      final m = markers[i];
      final center = _p(size, m.x.clamp(0.0, 1.0), m.y.clamp(0.0, 1.0));
      final radius = (size.width * 0.045).clamp(10, 18).toDouble();
      canvas.drawCircle(center, radius + 2.5, Paint()..color = Colors.white);
      canvas.drawCircle(center, radius, Paint()..color = m.color);
      if (m.label != null) {
        _drawText(canvas, m.label!, center, color: Colors.white, fontSize: radius * 0.95, bold: true);
      }
    }

    canvas.restore();
    canvas.drawRRect(
      outer,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawText(Canvas canvas, String text, Offset center,
      {required Color color, required double fontSize, bool bold = false}) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: bold ? FontWeight.w800 : FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant VolleyCourtPainter oldDelegate) {
    return oldDelegate.markers != markers ||
        oldDelegate.showZoneLabels != showZoneLabels ||
        oldDelegate.highlightZone != highlightZone ||
        oldDelegate.targetZones != targetZones;
  }
}
