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
    FakeGameStore store,
    FakeClock clock, {
    int? trials,
    RunnerContext? runner,
  }) => ReactionEngine(
    sink: sink,
    store: store,
    clock: clock,
    runner: runner,
    trials: trials,
  );

  // Waits out the random delay (fakeAsync timers), simulates a reaction of
  // exactly [reactionMs] by advancing the FakeClock, taps, and returns the
  // measured time — which equals reactionMs.
  int playTrial(
    ReactionEngine engine,
    FakeClock clock,
    FakeAsync async,
    int reactionMs,
  ) {
    var guard = 0;
    while (engine.state.stage != ReactionStage.ready && guard++ < 100) {
      async.elapse(const Duration(milliseconds: 100));
    }
    clock.advance(Duration(milliseconds: reactionMs));
    engine.tap();
    return engine.state.ms!;
  }

  test('a tap during the wait is "too soon" and restarts the trial', () {
    fakeAsync((async) {
      final engine = build(
        FakeGameSink(),
        FakeGameStore(),
        FakeClock(DateTime.utc(2026)),
      )..start();
      expect(engine.state.stage, ReactionStage.wait);

      engine.tap(); // jumped the gun
      expect(engine.state.stage, ReactionStage.tooSoon);
      expect(engine.state.trial, 0); // nothing recorded

      async.elapse(const Duration(milliseconds: 1000)); // pause → restart
      expect(engine.state.stage, ReactionStage.wait);
      expect(engine.state.trial, 0);
    });
  });

  test('measures the reaction time as the elapsed time since the stimulus', () {
    fakeAsync((async) {
      final clock = FakeClock(DateTime.utc(2026));
      final engine = build(FakeGameSink(), FakeGameStore(), clock, trials: 1)
        ..start();
      expect(playTrial(engine, clock, async, 247), 247);
    });
  });

  test('averages the times, keeps the best, and records the score', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final clock = FakeClock(DateTime.utc(2026));
      final engine = build(sink, store, clock, trials: 5)..start();

      const reactions = [200, 400, 250, 600, 300];
      for (final r in reactions) {
        expect(playTrial(engine, clock, async, r), r);
        async.elapse(const Duration(milliseconds: 1000)); // gap → next / finish
      }

      final avg = jsRound(reactions.reduce((a, b) => a + b) / reactions.length);
      expect(avg, 350);
      expect(sink.calls.single.domain, 'Processing Speed');
      expect(sink.calls.single.score, normalize('rt-avg', avg));
      expect(store.values[CsStoreKeys.rtAvg], avg);
      expect(engine.state.summary?.avg, avg);
      expect(engine.state.summary?.best, 200); // min — distinct from the mean
      expect(engine.state.summary?.previous, isNull); // clean first round
    });
  });

  test('carries the previous round average into the next summary', () {
    fakeAsync((async) {
      final store = FakeGameStore()..setInt(CsStoreKeys.rtAvg, 280);
      final clock = FakeClock(DateTime.utc(2026));
      final engine = build(FakeGameSink(), store, clock, trials: 2)..start();
      for (final r in const [300, 300]) {
        playTrial(engine, clock, async, r);
        async.elapse(const Duration(milliseconds: 1000));
      }
      expect(engine.state.summary?.avg, 300);
      expect(engine.state.summary?.previous, 280); // from the prior round
    });
  });

  test('runner mode calls onDone with the score and shows no summary', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final clock = FakeClock(DateTime.utc(2026));
      final runner = FakeRunnerContext(trials: 3);
      final engine = build(sink, store, clock, runner: runner.context)..start();

      for (final r in const [200, 300, 250]) {
        playTrial(engine, clock, async, r);
        async.elapse(const Duration(milliseconds: 1000));
      }

      final avg = jsRound((200 + 300 + 250) / 3);
      expect(runner.doneCount, 1);
      expect(runner.doneScore, normalize('rt-avg', avg));
      expect(sink.calls, hasLength(1));
      expect(engine.state.summary, isNull);
    });
  });
}
