import 'dart:math';

import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/nback/domain/nback_engine.dart';
import 'package:cogscroll/features/games/nback/domain/nback_sequence.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  NbackEngine build(
    FakeGameSink sink,
    FakeGameStore store, {
    int round = 6,
    int seed = 1,
    RunnerContext? runner,
  }) => NbackEngine(
    sink: sink,
    store: store,
    clock: FakeClock(DateTime.utc(2026)),
    runner: runner,
    round: round,
    random: Random(seed),
  );

  /// Plays the current round to completion, taking [decide] at each stimulus.
  void playRound(
    NbackEngine engine,
    FakeAsync async,
    bool Function(int idx, List<int> shapes, int n) decide,
  ) {
    final shapes = <int>[];
    var guard = 0;
    while (engine.state.phase == GamePhase.playing && guard++ < 500) {
      final st = engine.state;
      if (st.showing && st.fb == null && st.shape != null) {
        if (shapes.length == st.idx) shapes.add(st.shape!);
        if (decide(st.idx, shapes, st.n)) {
          engine.tap();
          async.elapse(const Duration(milliseconds: 800)); // past FB (760)
        } else {
          async
            ..elapse(const Duration(milliseconds: 1200)) // SHOW timeout (1150)
            ..elapse(const Duration(milliseconds: 800)); // FB / CR blank
        }
      } else {
        async.elapse(const Duration(milliseconds: 50));
      }
    }
  }

  // Respond perfectly: tap iff the stimulus is a genuine n-back match.
  bool perfectly(int idx, List<int> shapes, int n) =>
      idx >= n && shapes[idx] == shapes[idx - n];

  // The number of genuine matches a seeded round contains, at level n.
  int matchCount(int n, int round, int seed) {
    final seq = buildNbackSequence(n, round, Random(seed));
    var m = 0;
    for (var i = n; i < round; i++) {
      if (seq[i] == seq[i - n]) m++;
    }
    return m;
  }

  test('a perfect round records the level-aware score and persists state', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final engine = build(sink, store)..start();
      playRound(engine, async, perfectly);

      // N starts at 1; perfect acc = 100; norm = normalize('nback',(100,1)).
      expect(sink.calls, hasLength(1));
      expect(sink.calls.single.domain, 'Working Memory');
      expect(sink.calls.single.score, normalize('nback', (acc: 100, n: 1)));
      expect(store.values['nback-acc'], 100);
      // First qualifying round → streak 1 (two-consecutive: no jump yet).
      expect(store.values['nback-n'], 1);
      expect(store.values['nback-streak'], 1);
      expect(engine.state.phase, GamePhase.round);
      expect(engine.state.summary?.acc, 100);
      expect(engine.state.summary?.playedN, 1);
    });
  });

  test('two consecutive perfect rounds level N up (1 → 2)', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final engine = build(sink, store)..start();
      playRound(engine, async, perfectly); // round 1 → streak 1
      engine.start(); // continue
      playRound(engine, async, perfectly); // round 2 → streak 2 → level up

      expect(store.values['nback-n'], 2);
      expect(store.values['nback-streak'], 0);
      expect(engine.state.levelMsg, contains('Level up'));
      expect(engine.state.summary?.playedN, 1); // round 2 was played at N=1
    });
  });

  test(
    'tapping every trial: matches are hits, non-matches are false alarms',
    () {
      fakeAsync((async) {
        const seed = 5;
        final sink = FakeGameSink();
        final store = FakeGameStore();
        final engine = build(sink, store, seed: seed)..start();
        playRound(engine, async, (_, _, _) => true);

        final expected = jsRound(matchCount(1, 6, seed) / 6 * 100);
        expect(store.values['nback-acc'], expected);
      });
    },
  );

  test(
    'withholding every trial: matches are misses, non-matches are rejects',
    () {
      fakeAsync((async) {
        const seed = 5;
        final sink = FakeGameSink();
        final store = FakeGameStore();
        final engine = build(sink, store, seed: seed)..start();
        playRound(engine, async, (_, _, _) => false);

        // Correct = the rejections (non-matches); misses (matches) are wrong.
        final rejects = 6 - matchCount(1, 6, seed);
        expect(store.values['nback-acc'], jsRound(rejects / 6 * 100));
      });
    },
  );

  test('runner mode calls onDone and shows no standalone summary', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final runner = FakeRunnerContext(trials: 4);
      final engine = build(sink, store, runner: runner.context)..start();
      playRound(engine, async, perfectly);

      expect(runner.doneCount, 1);
      expect(runner.doneScore, normalize('nback', (acc: 100, n: 1)));
      expect(sink.calls, hasLength(1)); // recordResult fires in runner mode too
      expect(engine.state.summary, isNull); // no RoundEnd under a runner
    });
  });
}
