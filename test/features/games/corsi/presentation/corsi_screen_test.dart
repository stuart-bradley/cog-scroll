import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/games/corsi/presentation/corsi_playing.dart';
import 'package:cogscroll/features/games/corsi/presentation/corsi_screen.dart';
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

  /// Plays each trial to a resolution. The sequence is random/unknown, so we
  /// just tap the first cell up to twice: one tap resolves a mismatch, or (if
  /// it was the first cell) a second mismatches the next position — either way
  /// the trial resolves and the round advances.
  Future<void> drive(WidgetTester tester, {int maxTrials = 20}) async {
    for (var t = 0; t < maxTrials; t++) {
      if (find.byType(RoundEnd).evaluate().isNotEmpty) break;
      if (find.byType(CorsiPlaying).evaluate().isEmpty) break;
      await tester.pump(const Duration(seconds: 6)); // through show → recall
      for (var k = 0; k < 2; k++) {
        final cell0 = find.byKey(const ValueKey('corsi-cell-0'));
        if (cell0.evaluate().isEmpty) break;
        await tester.tap(cell0);
        await tester.pump(const Duration(milliseconds: 120));
      }
      await tester.pump(const Duration(milliseconds: 1200)); // past feedback
    }
  }

  testWidgets('plays a standalone round to a RoundEnd and records it', (
    tester,
  ) async {
    await tester.pumpWidget(host(const CorsiScreen()));
    expect(find.text('BEGIN'), findsOneWidget);

    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    expect(find.byType(CorsiPlaying), findsOneWidget);

    await drive(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RoundEnd), findsOneWidget);
    expect(sink.calls, hasLength(1));
    expect(sink.calls.single.domain, 'Spatial Reasoning');
    expect(store.values[CsStoreKeys.corsiSpan], isNotNull);
  });

  testWidgets('runner mode hides the TopBar, calls onDone, shows no RoundEnd', (
    tester,
  ) async {
    final runner = FakeRunnerContext(trials: 3);
    await tester.pumpWidget(host(CorsiScreen(runner: runner.context)));

    expect(find.byType(TopBar), findsNothing);

    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    await drive(tester);
    await tester.pumpAndSettle();

    expect(runner.doneCount, 1);
    expect(sink.calls, hasLength(1));
    expect(find.byType(RoundEnd), findsNothing);
  });
}
