import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volleystats_eps/screens/new_session_screen.dart';
import 'package:volleystats_eps/theme/app_theme.dart';
import 'package:volleystats_eps/widgets/court/volley_court_widget.dart';

void main() {
  testWidgets('selecting a target zone updates the summary text without layout errors', (tester) async {
    // Fenêtre de test assez grande pour que tout le formulaire (y compris le
    // terrain) soit visible sans avoir à faire défiler la vue.
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // NewSessionScreen ne dépend que de sessionProvider (en mémoire) : pas
    // besoin d'initialiser Hive/StorageService pour ce test.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const NewSessionScreen()),
      ),
    );
    await tester.pump();

    // Aucune zone choisie au départ.
    expect(find.text('Entraînement libre (toutes les zones)'), findsOneWidget);

    // Tape au centre du terrain (colonne du milieu, ligne avant) : zone 3.
    final court = find.byType(VolleyCourtWidget);
    expect(court, findsOneWidget);
    final courtCenter = tester.getTopLeft(court) +
        Offset(tester.getSize(court).width * 0.5, tester.getSize(court).height * 0.28);
    await tester.tapAt(courtCenter);
    await tester.pump();

    // Le texte doit apparaître sur UNE seule ligne lisible, pas éclaté verticalement.
    expect(find.text('Entraînement libre (toutes les zones)'), findsNothing);
    expect(find.textContaining('Zone(s) choisie(s)'), findsOneWidget);
    expect(find.text('Tout effacer'), findsOneWidget);

    // Aucune exception de layout (ex: RenderFlex overflow) ne doit avoir été levée.
    expect(tester.takeException(), isNull);
  });
}
