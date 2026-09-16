import '../models/court_zone.dart';
import '../models/serve.dart';
import '../models/serve_enums.dart';
import '../models/session.dart';
import '../models/student.dart';
import '../utils/id_generator.dart';
import '../widgets/court/court_geometry.dart';

/// Séries fictives pour la démonstration (§30-31) : permet de présenter
/// l'application sans devoir réaliser dix services réels.
class DemoDataService {
  static (double, double) _pointForZone(String zoneId) {
    final r = CourtGeometry.rectForZone(zoneId);
    return (r.center.dx, r.center.dy);
  }

  static const (double, double) _pointOut = (0.5, 0.965);
  static const (double, double) _pointNet = (0.5, CourtGeometry.netY);

  static Serve _serve({
    required String sessionId,
    required int number,
    required ServeResult result,
    String? zone,
    required String serveTypeId,
    ServeTrajectory trajectory = ServeTrajectory.tendue,
    bool footFault = false,
  }) {
    late double x, y;
    if (result == ServeResult.inCourt) {
      (x, y) = _pointForZone(zone!);
    } else if (result == ServeResult.net) {
      (x, y) = _pointNet;
    } else {
      (x, y) = _pointOut;
    }
    return Serve(
      id: newId(),
      sessionId: sessionId,
      number: number,
      timestamp: DateTime.now().subtract(Duration(minutes: (10 - number) * 2)),
      result: result,
      zone: zone,
      positionX: x,
      positionY: y,
      footFault: footFault,
      serveTypeId: serveTypeId,
      trajectory: trajectory,
      direction: CourtGeometry.directionForX(x),
    );
  }

  /// Série de démonstration principale — reproduit l'exemple du §30 (Alex).
  static Session buildDemoSession({DateTime? date}) {
    final sessionId = newId();
    final results = <Map<String, dynamic>>[
      {'r': ServeResult.inCourt, 'z': CourtZones.zone5, 't': 'tennis'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone5, 't': 'tennis'},
      {'r': ServeResult.out, 'z': null, 't': 'tennis', 'ff': true},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone5, 't': 'flottant'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone6, 't': 'tennis'},
      {'r': ServeResult.net, 'z': null, 't': 'tennis', 'ff': true},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone5, 't': 'flottant'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone5, 't': 'tennis'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone5, 't': 'flottant'},
      {'r': ServeResult.out, 'z': null, 't': 'tennis'},
    ];

    final serves = <Serve>[];
    for (var i = 0; i < results.length; i++) {
      final entry = results[i];
      serves.add(_serve(
        sessionId: sessionId,
        number: i + 1,
        result: entry['r'] as ServeResult,
        zone: entry['z'] as String?,
        serveTypeId: entry['t'] as String,
        trajectory: i.isEven ? ServeTrajectory.tendue : ServeTrajectory.cloche,
        footFault: entry['ff'] as bool? ?? false,
      ));
    }

    return Session(
      id: sessionId,
      student: const Student(
        name: 'Alex',
        className: '2nde 4',
        dominantHand: DominantHand.droitier,
        mainServeTypeId: 'tennis',
      ),
      date: date ?? DateTime.now().subtract(const Duration(days: 7)),
      serves: serves,
    );
  }

  /// Deuxième série du même élève, plus variée, pour illustrer la
  /// comparaison de progression (§19) dans l'historique.
  static Session buildDemoSessionImproved({DateTime? date}) {
    final sessionId = newId();
    final results = <Map<String, dynamic>>[
      {'r': ServeResult.inCourt, 'z': CourtZones.zone5, 't': 'tennis'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone1, 't': 'tennis'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone6, 't': 'flottant'},
      {'r': ServeResult.out, 'z': null, 't': 'tennis'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone2, 't': 'flottant'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone5, 't': 'tennis'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone4, 't': 'tennis'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone1, 't': 'flottant'},
      {'r': ServeResult.net, 'z': null, 't': 'tennis'},
      {'r': ServeResult.inCourt, 'z': CourtZones.zone6, 't': 'tennis'},
    ];

    final serves = <Serve>[];
    for (var i = 0; i < results.length; i++) {
      final entry = results[i];
      serves.add(_serve(
        sessionId: sessionId,
        number: i + 1,
        result: entry['r'] as ServeResult,
        zone: entry['z'] as String?,
        serveTypeId: entry['t'] as String,
        trajectory: i.isOdd ? ServeTrajectory.tendue : ServeTrajectory.cloche,
      ));
    }

    return Session(
      id: sessionId,
      student: const Student(
        name: 'Alex',
        className: '2nde 4',
        dominantHand: DominantHand.droitier,
        mainServeTypeId: 'tennis',
      ),
      date: date ?? DateTime.now(),
      serves: serves,
    );
  }
}
