import 'package:cogscroll/core/ui_kit/intro.dart';
import 'package:cogscroll/core/ui_kit/wide_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child), debugShowCheckedModeBanner: false);

void main() {
  group('Intro', () {
    testWidgets('renders text, footnote and legend, then settles', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const Intro(
            text: 'Ready?',
            startLabel: 'Begin',
            footnote: 'tap to start',
            legend: Text('legend', key: Key('legend')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ready?'), findsOneWidget);
      expect(find.text('TAP TO START'), findsOneWidget);
      expect(find.byKey(const Key('legend')), findsOneWidget);
    });

    testWidgets('fires onStart from the embedded button', (tester) async {
      var started = false;
      await tester.pumpWidget(
        _wrap(
          Intro(
            text: 'Ready?',
            startLabel: 'Begin',
            onStart: () => started = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(WideButton));
      expect(started, isTrue);
    });
  });
}
