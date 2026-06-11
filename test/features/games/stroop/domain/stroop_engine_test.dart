import 'dart:math';

import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_engine.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_state.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  StroopEngine build(
    FakeGameSink sink,
    FakeGameStore store,
    FakeClock clock, {
    int round = 8,
    int seed = 3,
  }) => StroopEngine(
    sink: sink,
    store: store,
    clock: clock,
    round: round,
    random: Random(seed),
  );

  FakeClock clockAt2026() => FakeClock(DateTime.utc(2026));

  int expectedInterference(List<int> cong, List<int> incong) {
    double mean(List<int> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
    return jsRound(mean(incong) - mean(cong));
  }

  /// Plays a full round, giving congruent trials [congMs] and incongruent
  /// trials [incongMs] of (clock) response time, tapping correctly unless
  /// [correct] is false. Returns the captured RT buckets.
  ({List<int> cong, List<int> incong}) playRound(
    StroopEngine engine,
    FakeAsync async,
    FakeClock clock, {
    required int congMs,
    required int incongMs,
    bool correct = true,
  }) {
    final cong = <int>[];
    final incong = <int>[];
    engine.start();
    var guard = 0;
    while (engine.state.phase == GamePhase.playing && guard++ < 500) {
      final st = engine.state;
      final stim = st.stim;
      if (st.fb == null && stim != null && st.picked == null) {
        final rt = stim.congruent ? congMs : incongMs;
        (stim.congruent ? cong : incong).add(rt);
        clock.advance(Duration(milliseconds: rt));
        final wrong = stim.options.firstWhere((o) => o != stim.shape);
        engine.pick(correct ? stim.shape : wrong);
        async.elapse(stroopFeedback + const Duration(milliseconds: 20));
      } else {
        async.elapse(const Duration(milliseconds: 20));
      }
    }
    return (cong: cong, incong: incong);
  }

  test('records the interference cost and persists level/streak/last', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final clock = clockAt2026();
      final engine = build(sink, store, clock);
      final rts = playRound(engine, async, clock, congMs: 300, incongMs: 500);
      final interference = expectedInterference(rts.cong, rts.incong);

      expect(sink.calls, hasLength(1));
      expect(sink.calls.single.domain, 'Attention & Inhibition');
      expect(
        sink.calls.single.score,
        normalize('stroop', (interferenceMs: interference, level: 1)),
      );
      expect(store.values[CsStoreKeys.stroopInterference], interference);
      expect(engine.state.summary?.interferenceMs, interference);
      expect(engine.state.summary?.playedLevel, 1);
      expect(engine.state.summary?.interferenceDelta, isNull);
    });
  });

  test('incongruent trials are slower, so interference is positive', () {
    fakeAsync((async) {
      final clock = clockAt2026();
      final engine = build(FakeGameSink(), FakeGameStore(), clock);
      final rts = playRound(engine, async, clock, congMs: 250, incongMs: 600);
      // Both buckets should be populated over 8 trials at a 0.35 congruent
      // rate; the slower incongruent mean lifts interference above zero.
      expect(rts.cong, isNotEmpty);
      expect(rts.incong, isNotEmpty);
      expect(engine.state.summary!.interferenceMs, greaterThan(0));
    });
  });

  test('a correct tap blooms, a wrong tap shakes', () {
    fakeAsync((async) {
      final clock = clockAt2026();
      final fbs = <StroopFeedback>[];
      // Tap correctly on even trials, wrong on odd.
      final engine = build(FakeGameSink(), FakeGameStore(), clock, round: 4)
        ..onChange = (s) {
          if (s.fb != null && s.phase == GamePhase.playing) fbs.add(s.fb!);
        }
        ..start();
      var guard = 0;
      final seen = <int>{};
      while (engine.state.phase == GamePhase.playing && guard++ < 500) {
        final st = engine.state;
        final stim = st.stim;
        if (st.fb == null && stim != null && !seen.contains(st.idx)) {
          seen.add(st.idx);
          clock.advance(const Duration(milliseconds: 300));
          final wrong = stim.options.firstWhere((o) => o != stim.shape);
          engine.pick(st.idx.isEven ? stim.shape : wrong);
          async.elapse(stroopFeedback + const Duration(milliseconds: 20));
        } else {
          async.elapse(const Duration(milliseconds: 20));
        }
      }
      expect(fbs[0], StroopFeedback.hit);
      expect(fbs[1], StroopFeedback.wrong);
      expect(fbs[2], StroopFeedback.hit);
      expect(fbs[3], StroopFeedback.wrong);
    });
  });

  test('a missed response deadline resolves as wrong', () {
    fakeAsync((async) {
      final clock = clockAt2026();
      final fbs = <StroopFeedback>[];
      final engine = build(FakeGameSink(), FakeGameStore(), clock, round: 2)
        ..onChange = (s) {
          if (s.fb != null && s.phase == GamePhase.playing) fbs.add(s.fb!);
        }
        ..start();
      // Never respond — let every window lapse (L1 window 3000ms).
      async.elapse(const Duration(seconds: 20));
      expect(fbs, everyElement(StroopFeedback.wrong));
      expect(fbs, hasLength(2));
      expect(engine.state.phase, GamePhase.round);
    });
  });

  test('two low-interference rounds level up (1 → 2)', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final clock = clockAt2026();
      final engine = build(FakeGameSink(), store, clock);
      playRound(engine, async, clock, congMs: 300, incongMs: 340); // ~40 < 90
      expect(store.values[CsStoreKeys.stroopLevel], 1);
      expect(store.values[CsStoreKeys.stroopStreak], 1);
      playRound(engine, async, clock, congMs: 300, incongMs: 340);
      expect(store.values[CsStoreKeys.stroopLevel], 2);
      expect(store.values[CsStoreKeys.stroopStreak], 0);
      expect(engine.state.levelMsg, contains('Level up'));
    });
  });

  test('two high-interference rounds ease the level down (2 → 1)', () {
    fakeAsync((async) {
      final store = FakeGameStore()..setInt(CsStoreKeys.stroopLevel, 2);
      final clock = clockAt2026();
      final engine = build(FakeGameSink(), store, clock);
      playRound(engine, async, clock, congMs: 200, incongMs: 600); // ~400 > 180
      playRound(engine, async, clock, congMs: 200, incongMs: 600);
      expect(store.values[CsStoreKeys.stroopLevel], 1);
      expect(engine.state.levelMsg, contains('Eased'));
    });
  });

  test('the second-play delta is interference vs the persisted last', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final clock = clockAt2026();
      final engine = build(FakeGameSink(), store, clock);
      final r1 = playRound(engine, async, clock, congMs: 300, incongMs: 500);
      final i1 = expectedInterference(r1.cong, r1.incong);
      final r2 = playRound(engine, async, clock, congMs: 300, incongMs: 420);
      final i2 = expectedInterference(r2.cong, r2.incong);
      expect(engine.state.summary?.interferenceDelta, i2 - i1);
    });
  });
}
