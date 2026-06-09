import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/wide_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child), debugShowCheckedModeBanner: false);

void main() {
  group('RoundEnd', () {
    testWidgets('shows the value and caption', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RoundEnd(
            value: '94%',
            caption: 'Accuracy',
            continueLabel: 'Continue',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('94%'), findsOneWidget);
      expect(find.text('ACCURACY'), findsOneWidget);
    });

    testWidgets('delta up = better renders the upward triangle only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const RoundEnd(
            value: '94%',
            caption: 'Accuracy',
            continueLabel: 'Continue',
            delta: (dir: DeltaDirection.up, text: '+3'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey(DeltaDirection.up)), findsOneWidget);
      expect(find.byKey(const ValueKey(DeltaDirection.down)), findsNothing);
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('delta down renders the downward triangle', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RoundEnd(
            value: '60%',
            caption: 'Accuracy',
            continueLabel: 'Continue',
            delta: (dir: DeltaDirection.down, text: '-4'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey(DeltaDirection.down)), findsOneWidget);
      expect(find.byKey(const ValueKey(DeltaDirection.up)), findsNothing);
    });

    testWidgets('renders sub and levelMsg only when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RoundEnd(
            value: '94%',
            caption: 'Accuracy',
            continueLabel: 'Continue',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rank 3'), findsNothing);
      expect(find.text('LEVEL UP'), findsNothing);

      await tester.pumpWidget(
        _wrap(
          const RoundEnd(
            value: '94%',
            caption: 'Accuracy',
            continueLabel: 'Continue',
            sub: 'Rank 3',
            levelMsg: 'Level up',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rank 3'), findsOneWidget);
      expect(find.text('LEVEL UP'), findsOneWidget);
    });

    testWidgets('fires onContinue from the embedded button', (tester) async {
      var continued = false;
      await tester.pumpWidget(
        _wrap(
          RoundEnd(
            value: '94%',
            caption: 'Accuracy',
            continueLabel: 'Continue',
            onContinue: () => continued = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(WideButton));
      expect(continued, isTrue);
    });
  });
}
