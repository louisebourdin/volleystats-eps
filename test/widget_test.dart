import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volleystats_eps/widgets/serve_progress_indicator.dart';

void main() {
  testWidgets('ServeProgressIndicator shows the current serve count', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ServeProgressIndicator(current: 3)),
      ),
    );

    expect(find.text('Service 3 / 10'), findsOneWidget);
  });
}
