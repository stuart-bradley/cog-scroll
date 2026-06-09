import 'package:cogscroll/core/ui_kit/countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child), debugShowCheckedModeBanner: false);

double _fillFactor(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor!;

void main() {
  group('Countdown', () {
    testWidgets('depletes the fill from full toward empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const Countdown(ms: 1000, trialKey: 'a')),
      );
      expect(_fillFactor(tester), closeTo(1, 0.02));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_fillFactor(tester), closeTo(0.5, 0.05));
    });

    testWidgets('restarts from full when trialKey changes, same State', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const Countdown(ms: 1000, trialKey: 'a')),
      );
      final state1 = tester.state<State<Countdown>>(find.byType(Countdown));
      await tester.pump(const Duration(milliseconds: 600));
      expect(_fillFactor(tester), lessThan(0.6));

      await tester.pumpWidget(
        _wrap(const Countdown(ms: 1000, trialKey: 'b')),
      );
      await tester.pump();
      final state2 = tester.state<State<Countdown>>(find.byType(Countdown));

      expect(identical(state1, state2), isTrue);
      expect(_fillFactor(tester), closeTo(1, 0.02));
    });
  });
}
