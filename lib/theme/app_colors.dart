import 'package:flutter/material.dart';

/// Palette de l'application : bleu/orange volley comme couleur principale,
/// et des couleurs sémantiques constantes pour les résultats
/// (toujours doublées d'une icône/texte, jamais la seule information — accessibilité).
class AppColors {
  AppColors._();

  // Identité "volley" : bleu profond (terrain / sport) + orange (ballon / énergie).
  static const primary = Color(0xFF1E4FD8);
  static const primaryDark = Color(0xFF12327F);
  static const accent = Color(0xFFFF7A1A);

  static const background = Color(0xFFF5F7FB);
  static const surface = Color(0xFFFFFFFF);

  // Résultats — sémantique constante dans toute l'app.
  static const success = Color(0xFF2E9E5B); // vert = réussite / IN
  static const error = Color(0xFFD9483B); // rouge = erreur / OUT
  static const warning = Color(0xFFE0752A); // orange = attention / FILET
  static const info = Color(0xFF2E6FE0); // bleu = information

  static const textPrimary = Color(0xFF1B2233);
  static const textSecondary = Color(0xFF5C6478);
  static const border = Color(0xFFE1E5EE);

  static const courtFloor = Color(0xFFEAF1FF);
  static const courtLine = Color(0xFF1E4FD8);
  static const netColor = Color(0xFF1B2233);
  static const outZone = Color(0xFFFBEAE8);
  static const piscineFill = Color(0xFFCFE0FF);
}
