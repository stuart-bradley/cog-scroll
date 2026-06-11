import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/trails/domain/trails_state.dart';
import 'package:cogscroll/features/games/trails/presentation/trails_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  late FakeGameSink sink;
  late FakeGameStore store;
  late FakeClock clock;

  setUp(() {
    sink = FakeGameSink();
    store = FakeGameStore();
    clock = FakeClock(DateTime.utc(2026));
  });

  Widget host(Widget child) => ProviderScope(
    overrides: [
      gameSinkProvider.overrideWithValue(sink),
      gameStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(clock),
    ],
    child: MaterialApp(home: child),
  );

  /// Taps the [count] dots in sequence order. Avoids `pumpAndSettle` while
  /// playing — the elapsed readout re-schedules a tick forever.
  Future<void> connectAll(WidgetTester tester, {int count = 8}) async {
    for (var i = 0; i < count; i++) {
      await tester.tap(find.byKey(ValueKey('trail-dot-$i')));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('plays a standalone round to a RoundEnd and records it', (
    tester,
  ) async {
    await tester.pumpWidget(host(const TrailsScreen(mode: TrailMode.a)));
    expect(find.text('START'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pump();
    clock.advance(const Duration(seconds: 12));
    await connectAll(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RoundEnd), findsOneWidget);
    expect(find.text('12.0'), findsOneWidget); // seconds hero metric
    expect(sink.calls, hasLength(1));
    expect(sink.calls.single.domain, 'Mental Flexibility');
    expect(store.values[CsStoreKeys.trailATime], 1.5); // pace: 12s / 8 targets
    expect(store.values[CsStoreKeys.trailALevel], 1);
  });

  testWidgets('the second round shows a pace-per-target delta', (
    tester,
  ) async {
    await tester.pumpWidget(host(const TrailsScreen(mode: TrailMode.a)));
    await tester.tap(find.text('START'));
    await tester.pump();
    clock.advance(const Duration(seconds: 16)); // pace 2.0 (16 / 8)
    await connectAll(tester);
    await tester.pumpAndSettle();
    expect(find.byType(RoundEnd), findsOneWidget); // level stays 1, count 8

    await tester.tap(find.text('AGAIN'));
    await tester.pump();
    clock.advance(const Duration(seconds: 8)); // pace 1.0 → 1.0 faster/target
    await connectAll(tester);
    await tester.pumpAndSettle();
    expect(find.text('1.0s/target faster'), findsOneWidget);
  });

  testWidgets('a slower second round shows a down-direction pace delta', (
    tester,
  ) async {
    await tester.pumpWidget(host(const TrailsScreen(mode: TrailMode.a)));
    await tester.tap(find.text('START'));
    await tester.pump();
    clock.advance(const Duration(seconds: 8)); // pace 1.0
    await connectAll(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('AGAIN'));
    await tester.pump();
    clock.advance(const Duration(seconds: 16)); // pace 2.0 → 1.0 slower/target
    await connectAll(tester);
    await tester.pumpAndSettle();
    expect(find.text('1.0s/target slower'), findsOneWidget);
    expect(find.byKey(const ValueKey(DeltaDirection.down)), findsOneWidget);
  });

  testWidgets('an unchanged pace suppresses the delta line', (tester) async {
    await tester.pumpWidget(host(const TrailsScreen(mode: TrailMode.a)));
    await tester.tap(find.text('START'));
    await tester.pump();
    clock.advance(const Duration(seconds: 8)); // pace 1.0
    await connectAll(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('AGAIN'));
    await tester.pump();
    clock.advance(const Duration(seconds: 8)); // pace 1.0 again → Δ 0.0
    await connectAll(tester);
    await tester.pumpAndSettle();
    expect(find.byType(RoundEnd), findsOneWidget);
    expect(find.textContaining('s/target'), findsNothing); // delta hidden
  });

  testWidgets('a level-up round surfaces the level message and sub line', (
    tester,
  ) async {
    await tester.pumpWidget(host(const TrailsScreen(mode: TrailMode.a)));
    Future<void> fastRound(String startButton) async {
      await tester.tap(find.text(startButton));
      await tester.pump();
      clock.advance(const Duration(seconds: 4)); // pace 0.5 → qualifies up
      await connectAll(tester);
      await tester.pumpAndSettle();
    }

    await fastRound('START'); // streak 1
    await fastRound('AGAIN'); // streak 2 → level up to L2

    expect(find.textContaining('LEVEL UP'), findsOneWidget); // Label uppercases
    expect(find.text('Level 1 · 8 targets'), findsOneWidget); // sub line
  });

  testWidgets('a wrong tap shakes the dot and the round does not advance', (
    tester,
  ) async {
    await tester.pumpWidget(host(const TrailsScreen(mode: TrailMode.a)));
    await tester.tap(find.text('START'));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('trail-dot-3')));
    await tester.pump();
    final shake = find.byType(Shake);
    expect(shake, findsOneWidget);
    // The shaken dot's label stays visible through the whole flash.
    expect(
      find.descendant(of: shake, matching: find.text('4')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.descendant(of: find.byType(Shake), matching: find.text('4')),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 200)); // flash over (360ms)
    expect(find.byType(Shake), findsNothing);
    expect(find.byType(RoundEnd), findsNothing);
    expect(sink.calls, isEmpty);
  });

  testWidgets('the TopBar readout ticks the elapsed time', (tester) async {
    await tester.pumpWidget(host(const TrailsScreen(mode: TrailMode.a)));
    await tester.tap(find.text('START'));
    await tester.pump();

    clock.advance(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 100)); // one tick
    expect(find.text('2.5S'), findsOneWidget); // Label upper-cases

    // Leave no live round behind (the tick timer re-arms forever).
    clock.advance(const Duration(seconds: 1));
    await connectAll(tester);
    await tester.pumpAndSettle();
  });

  testWidgets('Mode B titles the bar and alternates letter labels', (
    tester,
  ) async {
    await tester.pumpWidget(host(const TrailsScreen(mode: TrailMode.b)));
    expect(find.text('TRAIL MAKING · LETTERS'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pump();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);

    clock.advance(const Duration(seconds: 9));
    await connectAll(tester);
    await tester.pumpAndSettle();
    expect(find.byType(RoundEnd), findsOneWidget);
    expect(store.values[CsStoreKeys.trailBTime], 1.125); // pace: 9s / 8
  });

  testWidgets('runner mode hides the TopBar, calls onDone, no RoundEnd', (
    tester,
  ) async {
    final runner = FakeRunnerContext(points: 4);
    await tester.pumpWidget(
      host(TrailsScreen(mode: TrailMode.a, runner: runner.context)),
    );

    expect(find.byType(TopBar), findsNothing);

    await tester.tap(find.text('START'));
    await tester.pump();
    clock.advance(const Duration(seconds: 5));
    await connectAll(tester, count: 4);
    await tester.pumpAndSettle();

    expect(runner.doneCount, 1);
    expect(sink.calls, hasLength(1));
    expect(find.byType(RoundEnd), findsNothing);
  });
}
