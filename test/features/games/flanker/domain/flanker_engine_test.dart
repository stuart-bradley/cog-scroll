import 'dart:math';

import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_engine.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_trial.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  FlankerEngine build(
    FakeGameSink sink,
    FakeGameStore store, {
    int round = 6,
    int seed = 1,
    RunnerContext? runner,
  }) => FlankerEngine(
    sink: sink,
    store: store,
    clock: FakeClock(DateTime.utc(2026)),
    runner: runner,
    round: round,
    random: Random(seed),
  );

  /// Plays the current round to completion. [decide] returns the side to tap
  /// for the given target direction, or null to let the response window lapse.
  void playRound(
    FlankerEngine engine,
    FakeAsync async,
    FlankerDir? Function(FlankerDir target) decide,
  ) {
    var guard = 0;
    while (engine.state.phase == GamePhase.playing && guard++ < 500) {
      final st = engine.state;
      if (st.fb == null && st.dir != null) {
        final choice = decide(st.dir!);
        if (choice != null) {
          engine.respond(choice);
        } else {
          final windowMs = flankerParamsForLevel(st.level).windowMs;
          async.elapse(Duration(milliseconds: windowMs + 50)); // deadline
        }
        async.elapse(const Duration(milliseconds: 650)); // past feedback (620)
      } else {
        async.elapse(const Duration(milliseconds: 50));
      }
    }
  }

  // Tap the correct side every trial.
  FlankerDir perfectly(FlankerDir target) => target;
  // Tap the wrong side every trial.
  FlankerDir allWrong(FlankerDir target) => flipDir(target);

  Map<int, FlankerFeedback> playAndCapture(
    FlankerEngine engine,
    FakeAsync async,
    FlankerDir? Function(FlankerDir target) decide,
  ) {
    final cap = <int, FlankerFeedback>{};
    engine.onChange = (s) {
      if (s.phase == GamePhase.playing && s.fb != null) cap[s.idx] = s.fb!;
    };
    playRound(engine, async, decide);
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
      expect(sink.calls.single.domain, 'Sustained Attention');
      expect(
        sink.calls.single.score,
        normalize('flanker-acc', (acc: 100, level: 1)),
      );
      expect(store.values[CsStoreKeys.flankerAcc], 100);
      // First qualifying round → streak 1, no jump yet (two-consecutive).
      expect(store.values[CsStoreKeys.flankerLevel], 1);
      expect(store.values[CsStoreKeys.flankerStreak], 1);
      expect(engine.state.phase, GamePhase.round);
      expect(engine.state.summary?.acc, 100);
      expect(engine.state.summary?.playedLevel, 1);
      expect(engine.state.levelMsg, isNull);
    });
  });

  test('two consecutive perfect rounds level up (1 → 2)', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final engine = build(FakeGameSink(), store)..start();
      playRound(engine, async, perfectly); // streak 1
      engine.start();
      playRound(engine, async, perfectly); // streak 2 → level up

      expect(store.values[CsStoreKeys.flankerLevel], 2);
      expect(store.values[CsStoreKeys.flankerStreak], 0);
      expect(engine.state.levelMsg, contains('Level up'));
      expect(engine.state.summary?.playedLevel, 1); // round 2 played at L1
    });
  });

  test('two consecutive poor rounds ease the level down (2 → 1)', () {
    fakeAsync((async) {
      final store = FakeGameStore()..setInt(CsStoreKeys.flankerLevel, 2);
      final engine = build(FakeGameSink(), store)..start();
      playRound(engine, async, allWrong); // acc 0 → streak -1
      engine.start();
      playRound(engine, async, allWrong); // acc 0 → streak -2 → ease down
      expect(store.values[CsStoreKeys.flankerLevel], 1);
      expect(engine.state.levelMsg, contains('Eased'));
    });
  });

  test('the right side hits, the wrong side false-alarms', () {
    fakeAsync((async) {
      final engine = build(FakeGameSink(), FakeGameStore(), round: 4)..start();
      // Alternate correct / incorrect responses by trial parity.
      final cap = playAndCapture(
        engine,
        async,
        (target) => engine.state.idx.isEven ? target : flipDir(target),
      );
      expect(cap[0], FlankerFeedback.hit);
      expect(cap[1], FlankerFeedback.wrong);
      expect(cap[2], FlankerFeedback.hit);
      expect(cap[3], FlankerFeedback.wrong);
    });
  });

  test('a missed response deadline counts as wrong', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final engine = build(FakeGameSink(), store, round: 2)..start();
      final cap = playAndCapture(engine, async, (_) => null); // never respond
      expect(cap[0], FlankerFeedback.wrong);
      expect(cap[1], FlankerFeedback.wrong);
      expect(store.values[CsStoreKeys.flankerAcc], 0);
    });
  });

  test('runner mode calls onDone and shows no standalone summary', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final runner = FakeRunnerContext(trials: 4);
      final engine = build(sink, FakeGameStore(), runner: runner.context)
        ..start();
      playRound(engine, async, perfectly);

      expect(runner.doneCount, 1);
      expect(runner.doneScore, normalize('flanker-acc', (acc: 100, level: 1)));
      expect(sink.calls, hasLength(1));
      expect(engine.state.summary, isNull);
    });
  });
}
