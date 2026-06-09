import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/games/nback/presentation/nback_screen.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  late FakeGameSink sink;
  late FakeGameStore store;

  setUp(() {
    sink = FakeGameSink();
    store = FakeGameStore();
  });

  Widget host(Widget child) => ProviderScope(
    overrides: [
      gameSinkProvider.overrideWithValue(sink),
      gameStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(FakeClock(DateTime.utc(2026))),
    ],
    child: MaterialApp(home: child),
  );

  /// Taps "Match" through every remaining trial until the round leaves play.
  Future<void> drivePlaying(WidgetTester tester, {int maxTrials = 40}) async {
    for (var i = 0; i < maxTrials; i++) {
      final match = find.text('MATCH');
      if (match.evaluate().isEmpty) break;
      await tester.tap(match);
      await tester.pump(const Duration(milliseconds: 900));
    }
  }

  testWidgets('plays a standalone round to a RoundEnd and records it', (
    tester,
  ) async {
    await tester.pumpWidget(host(const NbackScreen()));
    expect(find.text('1-BACK'), findsOneWidget); // level chrome (upper-cased)
    expect(find.text('BEGIN'), findsOneWidget);

    await tester.tap(find.text('BEGIN'));
    await tester.pump(); // enter playing + first stimulus
    expect(find.byType(Shape), findsWidgets);
    expect(find.text('MATCH'), findsOneWidget);

    // The stimulus stays visible through the feedback motion.
    await tester.tap(find.text('MATCH'));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(Shape), findsWidgets);

    await drivePlaying(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RoundEnd), findsOneWidget);
    expect(sink.calls, hasLength(1));
    expect(sink.calls.single.domain, 'Working Memory');
    expect(store.values['nback-acc'], isNotNull);
  });

  testWidgets('runner mode hides the TopBar, calls onDone, shows no RoundEnd', (
    tester,
  ) async {
    final runner = FakeRunnerContext(trials: 3);
    await tester.pumpWidget(host(NbackScreen(runner: runner.context)));

    expect(find.byType(TopBar), findsNothing); // runner draws its own header

    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    await drivePlaying(tester);
    await tester.pumpAndSettle();

    expect(runner.doneCount, 1);
    expect(runner.doneScore, isNotNull);
    expect(sink.calls, hasLength(1)); // recordResult fires under a runner too
    expect(find.byType(RoundEnd), findsNothing); // no standalone RoundEnd
  });
}
