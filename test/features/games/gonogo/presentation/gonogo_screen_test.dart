import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/games/gonogo/presentation/gonogo_playing.dart';
import 'package:cogscroll/features/games/gonogo/presentation/gonogo_screen.dart';
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

  /// Taps every trial until the round leaves play (feedback 540 + ISI ≤ 1000).
  Future<void> drivePlaying(WidgetTester tester, {int maxTrials = 40}) async {
    for (var i = 0; i < maxTrials; i++) {
      if (find.byType(RoundEnd).evaluate().isNotEmpty) break;
      final playing = find.byType(GoNoGoPlaying);
      if (playing.evaluate().isEmpty) break;
      await tester.tap(playing);
      await tester.pump(const Duration(milliseconds: 1900));
    }
  }

  testWidgets('plays a standalone round to a RoundEnd and records it', (
    tester,
  ) async {
    await tester.pumpWidget(host(const GoNoGoScreen()));
    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.text('BEGIN'), findsOneWidget);

    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    expect(find.byType(GoNoGoPlaying), findsOneWidget);

    await drivePlaying(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RoundEnd), findsOneWidget);
    expect(sink.calls, hasLength(1));
    expect(sink.calls.single.domain, 'Attention & Inhibition');
    expect(store.values[CsStoreKeys.gngAcc], isNotNull);
    expect(store.values[CsStoreKeys.gngLevel], isNotNull);
  });

  testWidgets('runner mode hides the TopBar, calls onDone, shows no RoundEnd', (
    tester,
  ) async {
    final runner = FakeRunnerContext(trials: 4);
    await tester.pumpWidget(host(GoNoGoScreen(runner: runner.context)));

    expect(find.byType(TopBar), findsNothing);

    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    await drivePlaying(tester);
    await tester.pumpAndSettle();

    expect(runner.doneCount, 1);
    expect(runner.doneScore, isNotNull);
    expect(sink.calls, hasLength(1));
    expect(find.byType(RoundEnd), findsNothing);
  });
}
