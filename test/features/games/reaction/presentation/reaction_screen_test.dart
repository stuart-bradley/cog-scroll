import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/games/reaction/presentation/reaction_playing.dart';
import 'package:cogscroll/features/games/reaction/presentation/reaction_screen.dart';
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

  // Plays [trials] reaction trials: wait out the delay, tap, let the gap pass.
  Future<void> drive(WidgetTester tester, int trials) async {
    for (var t = 0; t < trials; t++) {
      await tester.pump(const Duration(seconds: 4)); // past the random wait
      await tester.tap(find.byType(ReactionPlaying));
      await tester.pump(
        const Duration(milliseconds: 1100),
      ); // gap → next/finish
    }
  }

  testWidgets('plays a standalone round to a RoundEnd and records it', (
    tester,
  ) async {
    await tester.pumpWidget(host(const ReactionScreen()));
    expect(find.text('BEGIN'), findsOneWidget);

    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    expect(find.text('WAIT FOR IT…'), findsOneWidget);

    await drive(tester, 5);
    await tester.pumpAndSettle();

    expect(find.byType(RoundEnd), findsOneWidget);
    expect(sink.calls.single.domain, 'Processing Speed');
    expect(store.values[CsStoreKeys.rtAvg], isNotNull);
  });

  testWidgets('runner mode hides the TopBar, calls onDone, shows no RoundEnd', (
    tester,
  ) async {
    final runner = FakeRunnerContext(trials: 3);
    await tester.pumpWidget(host(ReactionScreen(runner: runner.context)));

    expect(find.byType(TopBar), findsNothing);

    await tester.tap(find.text('BEGIN'));
    await tester.pump();
    await drive(tester, 3);
    await tester.pumpAndSettle();

    expect(runner.doneCount, 1);
    expect(sink.calls, hasLength(1));
    expect(find.byType(RoundEnd), findsNothing);
  });
}
