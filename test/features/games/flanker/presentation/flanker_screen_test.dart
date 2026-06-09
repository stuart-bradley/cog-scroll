import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/games/flanker/presentation/flanker_playing.dart';
import 'package:cogscroll/features/games/flanker/presentation/flanker_screen.dart';
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

  /// Responds (left zone) on every trial until the round leaves play.
  Future<void> drivePlaying(WidgetTester tester, {int maxTrials = 40}) async {
    for (var i = 0; i < maxTrials; i++) {
      if (find.byType(RoundEnd).evaluate().isNotEmpty) break;
      final playing = find.byType(FlankerPlaying);
      if (playing.evaluate().isEmpty) break;
      final center = tester.getCenter(playing);
      await tester.tapAt(Offset(center.dx - 60, center.dy)); // left tap zone
      await tester.pump(const Duration(milliseconds: 700)); // past feedback
    }
  }

  testWidgets('plays a standalone round to a RoundEnd and records it', (
    tester,
  ) async {
    await tester.pumpWidget(host(const FlankerScreen()));
    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.text('BEGIN'), findsOneWidget);

    await tester.tap(find.text('BEGIN'));
    await tester.pump(); // enter playing + first stimulus
    expect(find.byType(FlankerPlaying), findsOneWidget);

    await drivePlaying(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RoundEnd), findsOneWidget);
    expect(sink.calls, hasLength(1));
    expect(sink.calls.single.domain, 'Sustained Attention');
    expect(store.values[CsStoreKeys.flankerAcc], isNotNull);
    expect(store.values[CsStoreKeys.flankerLevel], isNotNull);
  });

  testWidgets('runner mode hides the TopBar, calls onDone, shows no RoundEnd', (
    tester,
  ) async {
    final runner = FakeRunnerContext(trials: 3);
    await tester.pumpWidget(host(FlankerScreen(runner: runner.context)));

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
