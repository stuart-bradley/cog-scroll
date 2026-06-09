import 'dart:math';

import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/gonogo/domain/gonogo_engine.dart';
import 'package:cogscroll/features/games/gonogo/domain/gonogo_state.dart';
import 'package:cogscroll/features/games/gonogo/domain/gonogo_trial.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  GoNoGoEngine build(
    FakeGameSink sink,
    FakeGameStore store, {
    int round = 8,
    int seed = 1,
    RunnerContext? runner,
  }) => GoNoGoEngine(
    sink: sink,
    store: store,
    clock: FakeClock(DateTime.utc(2026)),
    runner: runner,
    round: round,
    random: Random(seed),
  );

  /// Plays the round to completion. [tap] decides, given the current shape id,
  /// whether to tap (otherwise the response window lapses). Steps time in small
  /// increments and acts once per fresh trial, so it is robust to the exact
  /// feedback-window / ISI durations.
  void playRound(
    GoNoGoEngine engine,
    FakeAsync async,
    bool Function(int shape) tap,
  ) {
    var guard = 0;
    var actedIdx = -1;
    while (engine.state.phase == GamePhase.playing && guard++ < 4000) {
      final st = engine.state;
      final fresh =
          st.showing && st.fb == null && st.shape != null && st.idx != actedIdx;
      if (fresh) {
        actedIdx = st.idx;
        if (tap(st.shape!)) engine.tap(); // else: let the window lapse
      }
      async.elapse(const Duration(milliseconds: 40));
    }
  }

  // Tap iff Go (tap circles, withhold on No-Go) — a perfect player.
  bool perfectly(int shape) => shape == gngGoShape;
  // Tap iff No-Go (tap squares, miss circles) — every response wrong.
  bool allWrong(int shape) => shape != gngGoShape;

  Map<int, ({GngFeedback fb, int shape})> playAndCapture(
    GoNoGoEngine engine,
    FakeAsync async,
    bool Function(int shape) tap,
  ) {
    final cap = <int, ({GngFeedback fb, int shape})>{};
    engine.onChange = (s) {
      if (s.phase == GamePhase.playing && s.fb != null && s.shape != null) {
        cap[s.idx] = (fb: s.fb!, shape: s.shape!);
      }
    };
    playRound(engine, async, tap);
    engine.onChange = null;
    return cap;
  }

  test('a perfect round records the level-aware score and persists state', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final engine = build(sink, store)..start();
      playRound(engine, async, perfectly);

      expect(sink.calls, hasLength(1));
      expect(sink.calls.single.domain, 'Attention & Inhibition');
      expect(
        sink.calls.single.score,
        normalize('gng-acc', (acc: 100, level: 1)),
      );
      expect(store.values[CsStoreKeys.gngAcc], 100);
      expect(store.values[CsStoreKeys.gngLevel], 1);
      expect(store.values[CsStoreKeys.gngStreak], 1);
      expect(engine.state.summary?.acc, 100);
      expect(engine.state.summary?.playedLevel, 1);
    });
  });

  test('go-tap blooms, withhold pulses, both are correct', () {
    fakeAsync((async) {
      final engine = build(FakeGameSink(), FakeGameStore(), round: 12, seed: 4)
        ..start();
      final cap = playAndCapture(engine, async, perfectly);

      // Every resolved trial maps shape → the right correct-feedback motion.
      for (final entry in cap.entries) {
        final c = entry.value;
        if (c.shape == gngGoShape) {
          expect(c.fb, GngFeedback.correctGo, reason: 'idx ${entry.key}');
        } else {
          expect(c.fb, GngFeedback.correctWithhold, reason: 'idx ${entry.key}');
        }
      }
      // The seeded round exercises both branches.
      final shapes = cap.values.map((c) => c.shape).toSet();
      expect(shapes, contains(gngGoShape));
      expect(shapes.any((s) => s != gngGoShape), isTrue);
    });
  });

  test('tapping a No-Go and missing a Go both shake (wrong)', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final engine = build(FakeGameSink(), store, seed: 4)..start();
      final cap = playAndCapture(engine, async, allWrong);
      expect(cap.values.every((c) => c.fb == GngFeedback.wrong), isTrue);
      expect(store.values[CsStoreKeys.gngAcc], 0);
    });
  });

  test('two consecutive perfect rounds level up (1 → 2)', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final engine = build(FakeGameSink(), store)..start();
      playRound(engine, async, perfectly);
      engine.start();
      playRound(engine, async, perfectly);
      expect(store.values[CsStoreKeys.gngLevel], 2);
      expect(store.values[CsStoreKeys.gngStreak], 0);
      expect(engine.state.levelMsg, contains('Level up'));
    });
  });

  test('two consecutive poor rounds ease the level down (3 → 2)', () {
    fakeAsync((async) {
      final store = FakeGameStore()..setInt(CsStoreKeys.gngLevel, 3);
      final engine = build(FakeGameSink(), store)..start();
      playRound(engine, async, allWrong);
      engine.start();
      playRound(engine, async, allWrong);
      expect(store.values[CsStoreKeys.gngLevel], 2);
      expect(engine.state.levelMsg, contains('Eased'));
    });
  });

  test('runner mode calls onDone and shows no standalone summary', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final runner = FakeRunnerContext(trials: 6);
      final engine = build(sink, FakeGameStore(), runner: runner.context)
        ..start();
      playRound(engine, async, perfectly);

      expect(runner.doneCount, 1);
      expect(runner.doneScore, normalize('gng-acc', (acc: 100, level: 1)));
      expect(sink.calls, hasLength(1));
      expect(engine.state.summary, isNull);
    });
  });
}
