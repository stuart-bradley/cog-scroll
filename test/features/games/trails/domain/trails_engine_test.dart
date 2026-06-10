import 'dart:math';

import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/trails/domain/trails_engine.dart';
import 'package:cogscroll/features/games/trails/domain/trails_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  TrailsEngine build(
    FakeGameSink sink,
    FakeGameStore store,
    FakeClock clock, {
    TrailMode mode = TrailMode.a,
    int? count = 4,
    int seed = 1,
    RunnerContext? runner,
  }) => TrailsEngine(
    mode: mode,
    sink: sink,
    store: store,
    clock: clock,
    runner: runner,
    count: count,
    random: Random(seed),
  );

  FakeClock clockAt2026() => FakeClock(DateTime.utc(2026));

  /// Taps every target in order after advancing the clock so the round takes
  /// [seconds] in total.
  void playRound(
    TrailsEngine engine,
    FakeClock clock, {
    required double seconds,
  }) {
    engine.start();
    clock.advance(Duration(milliseconds: (seconds * 1000).round()));
    for (var i = 0; i < engine.state.count; i++) {
      engine.tap(i);
    }
  }

  test('taps in order fill targets and finish records mode/count-aware', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final clock = clockAt2026();
      final engine = build(sink, store, clock)..start();
      expect(engine.state.phase, GamePhase.playing);
      expect(engine.state.targets, hasLength(4));

      clock.advance(const Duration(seconds: 10));
      engine.tap(0);
      expect(engine.state.next, 1);
      [1, 2, 3].forEach(engine.tap);

      expect(engine.state.phase, GamePhase.round);
      expect(sink.calls, hasLength(1));
      expect(sink.calls.single.domain, 'Mental Flexibility');
      expect(
        sink.calls.single.score,
        normalize('trail-time', (seconds: 10.0, count: 4, mode: TrailMode.a)),
      );
      // The persisted display key stores pace (s/target): 10s / 4 = 2.5.
      expect(store.values[CsStoreKeys.trailATime], 2.5);
      // spt 2.5 sits between the up (1.7) and down (3.3) thresholds → no move.
      expect(store.values[CsStoreKeys.trailALevel], 1);
      expect(store.values[CsStoreKeys.trailAStreak], 0);
      expect(engine.state.summary?.seconds, 10.0);
      expect(engine.state.summary?.count, 4);
      expect(engine.state.summary?.playedLevel, 1);
      expect(engine.state.summary?.paceDelta, isNull);
      expect(engine.state.levelMsg, isNull);
    });
  });

  test('a wrong tap shake-flashes, does not advance, costs no time', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final clock = clockAt2026();
      final engine = build(sink, store, clock)
        ..start()
        ..tap(2); // out of order
      expect(engine.state.bad, 2);
      expect(engine.state.next, 0);

      async.elapse(const Duration(milliseconds: 400)); // past the 360ms flash
      expect(engine.state.bad, isNull);

      // Finish; the wrong tap left no penalty — only the clock matters.
      clock.advance(const Duration(seconds: 4));
      [0, 1, 2, 3].forEach(engine.tap);
      expect(engine.state.summary?.seconds, 4.0);
      expect(sink.calls, hasLength(1));
    });
  });

  test('a correct tap clears a lingering wrong-flash immediately', () {
    fakeAsync((async) {
      final engine = build(FakeGameSink(), FakeGameStore(), clockAt2026())
        ..start()
        ..tap(3);
      expect(engine.state.bad, 3);
      engine.tap(0);
      expect(engine.state.bad, isNull);
      expect(engine.state.next, 1);
    });
  });

  test('tapping an already-done target flashes it wrong', () {
    fakeAsync((async) {
      final engine = build(FakeGameSink(), FakeGameStore(), clockAt2026())
        ..start()
        ..tap(0)
        ..tap(0);
      expect(engine.state.bad, 0);
      expect(engine.state.next, 1);
    });
  });

  test('two consecutive fast rounds level up (1 → 2)', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final clock = clockAt2026();
      final engine = build(FakeGameSink(), store, clock);
      playRound(engine, clock, seconds: 4); // spt 1.0 < 1.7 → streak 1
      expect(store.values[CsStoreKeys.trailALevel], 1);
      expect(store.values[CsStoreKeys.trailAStreak], 1);
      playRound(engine, clock, seconds: 4); // streak 2 → level up

      expect(store.values[CsStoreKeys.trailALevel], 2);
      expect(store.values[CsStoreKeys.trailAStreak], 0);
      expect(engine.state.levelMsg, contains('Level up'));
      expect(engine.state.summary?.playedLevel, 1); // round 2 played at L1
    });
  });

  test('two consecutive slow rounds ease the level down (2 → 1)', () {
    fakeAsync((async) {
      final store = FakeGameStore()..setInt(CsStoreKeys.trailALevel, 2);
      final clock = clockAt2026();
      final engine = build(FakeGameSink(), store, clock);
      playRound(engine, clock, seconds: 16); // spt 4.0 > 3.3 → streak -1
      playRound(engine, clock, seconds: 16); // streak -2 → ease down

      expect(store.values[CsStoreKeys.trailALevel], 1);
      expect(engine.state.levelMsg, contains('Eased'));
    });
  });

  test('the level ladder drives the target count when not overridden', () {
    fakeAsync((async) {
      final store = FakeGameStore()..setInt(CsStoreKeys.trailALevel, 4);
      final engine = build(
        FakeGameSink(),
        store,
        clockAt2026(),
        count: null,
      )..start();
      expect(engine.state.level, 4);
      expect(engine.state.count, 20);
      expect(engine.state.targets, hasLength(20));
    });
  });

  test('Mode B alternates labels and persists under trail-b keys', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final clock = clockAt2026();
      final engine = build(sink, store, clock, mode: TrailMode.b);
      playRound(engine, clock, seconds: 8); // spt 2.0 < 3.0 → streak 1

      expect(
        engine.state.targets.map((t) => t.label),
        ['1', 'A', '2', 'B'],
      );
      expect(store.values[CsStoreKeys.trailBTime], 2.0); // 8s / 4 targets
      expect(store.values[CsStoreKeys.trailBLevel], 1);
      expect(store.values[CsStoreKeys.trailBStreak], 1);
      expect(store.values.containsKey(CsStoreKeys.trailATime), isFalse);
      expect(
        sink.calls.single.score,
        normalize('trail-time', (seconds: 8.0, count: 4, mode: TrailMode.b)),
      );
    });
  });

  test('Mode B grades on its own (more lenient) staircase thresholds', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final clock = clockAt2026();
      final engine = build(FakeGameSink(), store, clock, mode: TrailMode.b);
      // spt 2.5 levels Mode B up (< 3.0) where Mode A would hold (> 1.7).
      playRound(engine, clock, seconds: 10);
      playRound(engine, clock, seconds: 10);
      expect(store.values[CsStoreKeys.trailBLevel], 2);
    });
  });

  test('the elapsed readout ticks from the injected clock', () {
    fakeAsync((async) {
      final clock = clockAt2026();
      final engine = build(FakeGameSink(), FakeGameStore(), clock)..start();
      expect(engine.state.elapsed, 0);

      clock.advance(const Duration(milliseconds: 2500));
      async.elapse(const Duration(milliseconds: 100)); // one tick
      expect(engine.state.elapsed, 2.5);
    });
  });

  test('the second-play delta is pace (s/target) vs the persisted last', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final clock = clockAt2026();
      final engine = build(FakeGameSink(), store, clock); // count 4
      playRound(engine, clock, seconds: 10); // pace 2.5
      playRound(engine, clock, seconds: 8); // pace 2.0
      expect(engine.state.summary?.paceDelta, -0.5); // faster per target
      playRound(engine, clock, seconds: 11); // pace 2.75
      expect(engine.state.summary?.paceDelta, closeTo(0.75, 1e-9)); // slower
    });
  });

  test('pace delta stays comparable when a level-up changes the count', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final clock = clockAt2026();
      // Level ladder drives the count (no override), starting L1 = 8 targets.
      final engine = build(FakeGameSink(), store, clock, count: null);
      playRound(engine, clock, seconds: 8); // L1 count 8, pace 1.0 → streak 1
      playRound(engine, clock, seconds: 8); // pace 1.0 → streak 2 → level up
      expect(store.values[CsStoreKeys.trailALevel], 2);

      // L2 = 12 targets. Same 1.0 s/target pace ⇒ 12s total — raw seconds
      // would read "+4s slower", but the pace delta correctly reads no change.
      playRound(engine, clock, seconds: 12);
      expect(engine.state.summary?.count, 12);
      expect(engine.state.summary?.seconds, 12.0);
      expect(engine.state.summary?.paceDelta, closeTo(0, 1e-9));
    });
  });

  test('runner mode: points sets the count, onDone fires, no summary', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final runner = FakeRunnerContext(points: 6);
      final clock = clockAt2026();
      final engine = build(
        sink,
        FakeGameStore(),
        clock,
        count: null,
        runner: runner.context,
      )..start();
      expect(engine.state.count, 6);

      clock.advance(const Duration(seconds: 6));
      for (var i = 0; i < 6; i++) {
        engine.tap(i);
      }

      expect(runner.doneCount, 1);
      expect(
        runner.doneScore,
        normalize('trail-time', (seconds: 6.0, count: 6, mode: TrailMode.a)),
      );
      expect(sink.calls, hasLength(1));
      expect(engine.state.summary, isNull);
    });
  });

  test('taps are ignored outside the playing phase', () {
    fakeAsync((async) {
      final clock = clockAt2026();
      final engine = build(FakeGameSink(), FakeGameStore(), clock)
        ..tap(0); // still on intro
      expect(engine.state.next, 0);
      playRound(engine, clock, seconds: 10);
      engine.tap(0); // round phase
      expect(engine.state.bad, isNull);
    });
  });
}
