import 'dart:math';

import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/reaction/domain/reaction_engine.dart';
import 'package:cogscroll/features/games/reaction/domain/reaction_state.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  ReactionEngine build(
    FakeGameSink sink,
    FakeGameStore store, {
    int? trials,
    int seed = 1,
    RunnerContext? runner,
  }) => ReactionEngine(
    sink: sink,
    store: store,
    clock: FakeClock(DateTime.utc(2026)),
    runner: runner,
    trials: trials,
    random: Random(seed),
  );

  // Waits out the random delay, "reacts" after [reactionMs], taps, and returns
  // the measured reaction time the engine recorded.
  int playTrial(ReactionEngine engine, FakeAsync async, int reactionMs) {
    var guard = 0;
    while (engine.state.stage != ReactionStage.ready && guard++ < 100) {
      async.elapse(const Duration(milliseconds: 100));
    }
    async.elapse(Duration(milliseconds: reactionMs));
    engine.tap();
    return engine.state.ms!;
  }

  test('a tap during the wait is "too soon" and restarts the trial', () {
    fakeAsync((async) {
      final engine = build(FakeGameSink(), FakeGameStore())..start();
      expect(engine.state.stage, ReactionStage.wait);

      engine.tap(); // jumped the gun
      expect(engine.state.stage, ReactionStage.tooSoon);
      expect(engine.state.trial, 0); // nothing recorded

      async.elapse(const Duration(milliseconds: 1000)); // pause → restart
      expect(engine.state.stage, ReactionStage.wait);
      expect(engine.state.trial, 0);
    });
  });

  test(
    'averages the reaction times and records the processing-speed score',
    () {
      fakeAsync((async) {
        final sink = FakeGameSink();
        final store = FakeGameStore();
        final engine = build(sink, store, trials: 5)..start();

        final measured = <int>[];
        for (var t = 0; t < 5; t++) {
          measured.add(playTrial(engine, async, 250));
          async.elapse(
            const Duration(milliseconds: 1100),
          ); // gap → next / finish
        }

        final avg = jsRound(measured.reduce((a, b) => a + b) / measured.length);
        expect(sink.calls.single.domain, 'Processing Speed');
        expect(sink.calls.single.score, normalize('rt-avg', avg));
        expect(store.values[CsStoreKeys.rtAvg], avg);
        expect(engine.state.summary?.avg, avg);
        expect(engine.state.summary?.best, measured.reduce(min));
      });
    },
  );

  test('runner mode calls onDone with the score and shows no summary', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final runner = FakeRunnerContext(trials: 3);
      final engine = build(sink, store, runner: runner.context)..start();

      final measured = <int>[];
      for (var t = 0; t < 3; t++) {
        measured.add(playTrial(engine, async, 200));
        async.elapse(const Duration(milliseconds: 1100));
      }

      final avg = jsRound(measured.reduce((a, b) => a + b) / measured.length);
      expect(runner.doneCount, 1);
      expect(runner.doneScore, normalize('rt-avg', avg));
      expect(sink.calls, hasLength(1));
      expect(engine.state.summary, isNull);
    });
  });
}
