import 'package:flutter/services.dart';

/// Contrôle du champ « Prénom ou pseudonyme » pour éviter les noms farfelus
/// ou grossiers saisis par les élèves.

const int kNameMaxLength = 20;

/// Lettres (accents compris), espace, tiret et apostrophe uniquement.
final RegExp _allowedChars = RegExp(r"[a-zA-ZÀ-ÖØ-öø-ÿŒœ '’-]");

/// À brancher sur le TextField : bloque chiffres, émojis, symboles et la
/// saisie au-delà de [kNameMaxLength] caractères.
final List<TextInputFormatter> kNameInputFormatters = [
  FilteringTextInputFormatter.allow(_allowedChars),
  LengthLimitingTextInputFormatter(kNameMaxLength),
];

/// Mots interdits quand ils forment un mot entier (ils peuvent apparaître
/// dans des prénoms normaux, ex. « con » dans « Constance »).
const Set<String> _blockedWords = {
  'con', 'cons', 'conne', 'connes', 'cul', 'pd', 'fdp', 'ntm', 'tg', 'nique',
  'niquer', 'bite', 'zob', 'teub', 'chier', 'pute', 'putes', 'gueule', 'gogol',
  'nazi', 'caca', 'pipi', 'prout', 'zizi', 'sexe', 'sex', 'chatte', 'pedale',
  'foutre', 'suce', 'sucer', 'mongol', 'debile', 'abruti', 'idiot', 'nul',
  'test', 'toto', 'lol', 'mdr', 'ptdr', 'xd', 'bg', 'boloss', 'bouffon',
  'fuck', 'shit', 'bitch', 'dick', 'ass', 'wtf', 'personne', 'moi', 'rien',
  'anonyme', 'inconnu', 'prof', 'professeur',
};

/// Morceaux interdits n'importe où dans le nom (espaces et tirets retirés).
const List<String> _blockedFragments = [
  'connard', 'connasse', 'salope', 'salaud', 'encule', 'enfoire', 'batard',
  'putain', 'merde', 'couille', 'branleu', 'branlet', 'petasse', 'pouffiasse',
  'negre', 'bougnoul', 'youpin', 'tapette', 'tarlouze', 'fiotte', 'gouine',
  'hitler', 'porn', 'filsdepute', 'tamere', 'tonpere', 'pedophile',
  'fuck', 'bitch', 'motherf', 'nigg', 'zgeg', 'chibre', 'teube',
];

/// Minuscules, sans accents, lettres répétées réduites (« merdeee » → « merde »).
String _normalize(String input) {
  const from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿœ’';
  const to = 'aaaaaaceeeeiiiinooooouuuuyyo\'';
  final buffer = StringBuffer();
  for (final ch in input.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString().replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
}

/// Nettoie la saisie avant enregistrement : espaces en trop retirés.
String cleanName(String input) => input.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Renvoie un message d'erreur, ou `null` si le nom est accepté.
/// Un champ vide renvoie `null` (le bouton reste simplement grisé).
String? validateName(String input) {
  final name = cleanName(input);
  if (name.isEmpty) return null;

  if (!RegExp(r"^[a-zA-ZÀ-ÖØ-öø-ÿŒœ '’-]+$").hasMatch(name)) {
    return 'Uniquement des lettres, espaces, tirets ou apostrophes.';
  }
  if (name.length > kNameMaxLength) return '$kNameMaxLength caractères maximum.';

  final letters = name.replaceAll(RegExp(r"[ '’-]"), '');
  if (letters.length < 2) return 'Au moins 2 lettres.';
  if (RegExp(r'(.)\1\1', caseSensitive: false).hasMatch(letters)) {
    return 'Pas plus de 2 fois la même lettre d\'affilée.';
  }

  final normalized = _normalize(name);
  if (!RegExp('[aeiouy]').hasMatch(normalized)) return 'Écris un vrai prénom ou pseudonyme.';

  final words = normalized.split(RegExp(r"[ '’-]+"));
  final joined = words.join();
  final blockedWords = _blockedWords.map(_normalize).toSet();
  if (words.any(blockedWords.contains) ||
      blockedWords.contains(joined) ||
      _blockedFragments.map(_normalize).any(joined.contains)) {
    return 'Ce nom n\'est pas autorisé. Utilise ton prénom.';
  }
  return null;
}
