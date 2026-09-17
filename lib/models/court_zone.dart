/// Les 6 zones du terrain adverse + la zone centrale "Piscine".
/// Représentées par de simples identifiants (String) pour rester faciles
/// à sérialiser (Hive/JSON) et à étendre.
class CourtZones {
  static const zone1 = 'zone1';
  static const zone2 = 'zone2';
  static const zone3 = 'zone3';
  static const zone4 = 'zone4';
  static const zone5 = 'zone5';
  static const zone6 = 'zone6';
  static const piscine = 'piscine';

  /// Ordre d'affichage utilisé dans les statistiques et graphiques.
  static const List<String> orderedForStats = [
    zone1,
    zone2,
    zone3,
    zone4,
    zone5,
    zone6,
    piscine,
  ];

  /// Zones proches du filet : un service qui y atterrit est un service "court".
  static const List<String> shortZones = [zone2, zone3, zone4];

  /// Zones proches de la ligne de fond : un service qui y atterrit est un service "long".
  static const List<String> longZones = [zone5, zone6, zone1];

  static bool isShort(String zoneId) => shortZones.contains(zoneId);

  static bool isLong(String zoneId) => longZones.contains(zoneId);

  /// 'Service court' / 'Service long', ou null pour la Piscine (ni court ni long).
  static String? depthLabel(String zoneId) {
    if (isShort(zoneId)) return 'Service court';
    if (isLong(zoneId)) return 'Service long';
    return null;
  }

  static String label(String zoneId) {
    if (zoneId == piscine) return 'Piscine';
    return 'Zone ${zoneId.replaceAll('zone', '')}';
  }

  static String shortLabel(String zoneId) {
    if (zoneId == piscine) return 'Piscine';
    return zoneId.replaceAll('zone', '');
  }
}
