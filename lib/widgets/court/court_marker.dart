import 'package:flutter/material.dart';

/// Un impact affiché sur le terrain (service en cours de saisie, ou un des
/// 10 impacts de la carte de synthèse).
class CourtMarker {
  final double x;
  final double y;
  final Color color;
  final String? label;

  const CourtMarker({required this.x, required this.y, required this.color, this.label});
}
