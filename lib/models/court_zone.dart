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

  /// Le service a atterri exactement sur la ligne entre deux zones voisines
  /// de la même rangée (jamais avant/arrière) — voir [CourtGeometry]. Jamais
  /// considérée comme une zone "visée" : informatif uniquement, notamment
  /// pour repérer dans les stats si une ligne précise revient souvent du
  /// côté des aces.
  static const interZone34 = 'inter_zone3_zone4';
  static const interZone23 = 'inter_zone2_zone3';
  static const interZone56 = 'inter_zone5_zone6';
  static const interZone16 = 'inter_zone1_zone6';

  static const List<String> interZones = [interZone34, interZone23, interZone56, interZone16];

  static bool isInterZone(String zoneId) => interZones.contains(zoneId);

  /// 'Service court' / 'Service long', ou null pour la Piscine (ni court ni long).
  static String? depthLabel(String zoneId) {
    if (isShort(zoneId)) return 'Service court';
    if (isLong(zoneId)) return 'Service long';
    return null;
  }

  static String label(String zoneId) {
    if (zoneId == piscine) return 'Piscine';
    switch (zoneId) {
      case interZone34:
        return 'Inter zone 3-4';
      case interZone23:
        return 'Inter zone 2-3';
      case interZone56:
        return 'Inter zone 5-6';
      case interZone16:
        return 'Inter zone 1-6';
    }
    return 'Zone ${zoneId.replaceAll('zone', '')}';
  }

  static String shortLabel(String zoneId) {
    if (zoneId == piscine) return 'Piscine';
    return zoneId.replaceAll('zone', '');
  }
}
