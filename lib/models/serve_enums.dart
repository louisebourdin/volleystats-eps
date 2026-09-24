import 'package:flutter/material.dart';

/// Résultat d'un service.
enum ServeResult { inCourt, out, net }

extension ServeResultX on ServeResult {
  String get label {
    switch (this) {
      case ServeResult.inCourt:
        return 'IN';
      case ServeResult.out:
        return 'OUT';
      case ServeResult.net:
        return 'FILET';
    }
  }

  static ServeResult fromName(String name) =>
      ServeResult.values.firstWhere((e) => e.name == name, orElse: () => ServeResult.out);
}

/// Trajectoire du service.
enum ServeTrajectory { cloche, tendue }

extension ServeTrajectoryX on ServeTrajectory {
  String get label => this == ServeTrajectory.cloche ? 'Cloche' : 'Tendue';
  String get shortLabel => this == ServeTrajectory.cloche ? 'Cloche' : 'Tendu';

  static ServeTrajectory fromName(String name) =>
      ServeTrajectory.values.firstWhere((e) => e.name == name, orElse: () => ServeTrajectory.cloche);
}

/// Direction du service (peut être déduite de la zone, mais reste un champ à part).
enum ServeDirection { gauche, centre, droite }

extension ServeDirectionX on ServeDirection {
  String get label {
    switch (this) {
      case ServeDirection.gauche:
        return 'Gauche';
      case ServeDirection.centre:
        return 'Centre';
      case ServeDirection.droite:
        return 'Droite';
    }
  }

  static ServeDirection fromName(String name) =>
      ServeDirection.values.firstWhere((e) => e.name == name, orElse: () => ServeDirection.centre);
}

/// Qualité du lancer de balle (facultatif).
enum TossQuality { bon, tropDevant, tropDerriere, tropHaut, tropBas, irregulier }

extension TossQualityX on TossQuality {
  String get label {
    switch (this) {
      case TossQuality.bon:
        return 'Bon';
      case TossQuality.tropDevant:
        return 'Trop devant';
      case TossQuality.tropDerriere:
        return 'Trop derrière';
      case TossQuality.tropHaut:
        return 'Trop haut';
      case TossQuality.tropBas:
        return 'Trop bas';
      case TossQuality.irregulier:
        return 'Irrégulier';
    }
  }

  static TossQuality? fromName(String? name) {
    if (name == null) return null;
    return TossQuality.values.firstWhereOrNull((e) => e.name == name);
  }
}

/// Qualité du contact avec le ballon (facultatif).
enum ContactQuality { centre, decentre, difficile }

extension ContactQualityX on ContactQuality {
  String get label {
    switch (this) {
      case ContactQuality.centre:
        return 'Centré';
      case ContactQuality.decentre:
        return 'Décentré';
      case ContactQuality.difficile:
        return 'Contact difficile';
    }
  }

  static ContactQuality? fromName(String? name) {
    if (name == null) return null;
    return ContactQuality.values.firstWhereOrNull((e) => e.name == name);
  }
}

/// Puissance du service (facultatif).
enum ServePower { faible, moyenne, forte }

extension ServePowerX on ServePower {
  String get label {
    switch (this) {
      case ServePower.faible:
        return 'Faible';
      case ServePower.moyenne:
        return 'Moyenne';
      case ServePower.forte:
        return 'Forte';
    }
  }

  static ServePower? fromName(String? name) {
    if (name == null) return null;
    return ServePower.values.firstWhereOrNull((e) => e.name == name);
  }
}

/// Intention du service (facultatif).
enum ServeIntention { securiser, viserZone, mettreEnDifficulte, servicePuissant }

extension ServeIntentionX on ServeIntention {
  String get label {
    switch (this) {
      case ServeIntention.securiser:
        return 'Sécuriser';
      case ServeIntention.viserZone:
        return 'Viser une zone';
      case ServeIntention.mettreEnDifficulte:
        return 'Mettre en difficulté';
      case ServeIntention.servicePuissant:
        return 'Service puissant';
    }
  }

  static ServeIntention? fromName(String? name) {
    if (name == null) return null;
    return ServeIntention.values.firstWhereOrNull((e) => e.name == name);
  }
}

/// Qualité de la réception adverse après un service IN, uniquement relevée
/// en "mode avec réception". Seul [poste3] correspond à une réception
/// maîtrisée (relance propre vers le passeur) : toutes les autres valeurs
/// traduisent un danger provoqué par le service.
enum ReceptionQuality { poste3, zone2, zone4, horsCible, ace }

extension ReceptionQualityX on ReceptionQuality {
  String get label {
    switch (this) {
      case ReceptionQuality.poste3:
        return 'Poste 3 (réception maîtrisée)';
      case ReceptionQuality.zone2:
        return 'Déviée en zone 2';
      case ReceptionQuality.zone4:
        return 'Déviée en zone 4';
      case ReceptionQuality.horsCible:
        return 'Imprécise / ailleurs';
      case ReceptionQuality.ace:
        return 'Ace (point direct)';
    }
  }

  String get shortLabel {
    switch (this) {
      case ReceptionQuality.poste3:
        return 'Poste 3';
      case ReceptionQuality.zone2:
        return 'Zone 2';
      case ReceptionQuality.zone4:
        return 'Zone 4';
      case ReceptionQuality.horsCible:
        return 'Ailleurs';
      case ReceptionQuality.ace:
        return 'Ace';
    }
  }

  /// Le service a mis l'adversaire en danger dès que la réception ne repart
  /// pas proprement vers le poste 3.
  bool get isDangerous => this != ReceptionQuality.poste3;

  static ReceptionQuality? fromName(String? name) {
    if (name == null) return null;
    return ReceptionQuality.values.firstWhereOrNull((e) => e.name == name);
  }
}

/// Main dominante de l'élève.
enum DominantHand { droitier, gaucher }

extension DominantHandX on DominantHand {
  String get label => this == DominantHand.droitier ? 'Droitier' : 'Gaucher';

  static DominantHand fromName(String name) =>
      DominantHand.values.firstWhere((e) => e.name == name, orElse: () => DominantHand.droitier);
}

/// Définition d'un type de service. Architecture ouverte : il suffit d'ajouter
/// une nouvelle constante à [ServeTypes.all] pour supporter un nouveau type,
/// sans toucher au reste de l'application (formulaire, stats, conseils).
class ServeTypeDef {
  final String id;
  final String label;
  final IconData icon;

  const ServeTypeDef({required this.id, required this.label, required this.icon});
}

class ServeTypes {
  static const cuillere = ServeTypeDef(id: 'cuillere', label: 'Cuillère', icon: Icons.arrow_upward_rounded);
  static const tennis = ServeTypeDef(id: 'tennis', label: 'Tennis', icon: Icons.sports_tennis);
  static const flottant = ServeTypeDef(id: 'flottant', label: 'Flottant', icon: Icons.air_rounded);
  static const smashe = ServeTypeDef(id: 'smashe', label: 'Smashé', icon: Icons.bolt_rounded);

  static const List<ServeTypeDef> all = [cuillere, tennis, flottant, smashe];

  static ServeTypeDef byId(String id) => all.firstWhereOrNull((e) => e.id == id) ?? tennis;
}

/// Petit utilitaire (évite une dépendance sur collection/package externe).
extension FirstWhereOrNullX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
