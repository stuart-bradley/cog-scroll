import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child), debugShowCheckedModeBanner: false);

void main() {
  group('TopBar', () {
    testWidgets('renders the title upper-cased', (tester) async {
      await tester.pumpWidget(_wrap(const TopBar(title: 'n-back')));
      expect(find.text('N-BACK'), findsOneWidget);
    });

    testWidgets('hides the back chevron when onBack is null', (tester) async {
      await tester.pumpWidget(_wrap(const TopBar(title: 'x')));
      expect(find.byType(CustomPaint), findsNothing);
    });

    testWidgets('shows the back chevron and fires onBack when tapped', (
      tester,
    ) async {
      var backs = 0;
      await tester.pumpWidget(
        _wrap(TopBar(title: 'x', onBack: () => backs++)),
      );
      expect(find.byType(CustomPaint), findsOneWidget);
      await tester.tap(find.byType(CustomPaint));
      expect(backs, 1);
    });

    testWidgets('renders the trailing slot', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TopBar(title: 'x', trailing: Text('right')),
        ),
      );
      expect(find.text('right'), findsOneWidget);
    });
  });
}
