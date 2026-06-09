import 'dart:math';

import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/corsi/domain/corsi_engine.dart';
import 'package:cogscroll/features/games/corsi/domain/corsi_state.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  CorsiEngine build(
    FakeGameSink sink,
    FakeGameStore store, {
    int trials = 6,
    int seed = 1,
    RunnerContext? runner,
  }) => CorsiEngine(
    sink: sink,
    store: store,
    clock: FakeClock(DateTime.utc(2026)),
    runner: runner,
    trials: trials,
    random: Random(seed),
  );

  /// Watches the flashing sequence (the lit cells, in order) while elapsing to
  /// the recall stage.
  List<int> watchSequence(CorsiEngine engine, FakeAsync async) {
    final seq = <int>[];
    engine.onChange = (s) {
      if (s.stage == CorsiStage.show &&
          s.lit >= 0 &&
          (seq.isEmpty || seq.last != s.lit)) {
        seq.add(s.lit);
      }
    };
    var guard = 0;
    while (engine.state.stage == CorsiStage.show && guard++ < 300) {
      async.elapse(const Duration(milliseconds: 80));
    }
    engine.onChange = null;
    return seq;
  }

  /// Plays one trial: watch the sequence, then either tap it back correctly or
  /// tap a wrong cell, then clear the feedback window.
  void playTrial(CorsiEngine engine, FakeAsync async, {required bool correct}) {
    final seq = watchSequence(engine, async);
    if (correct) {
      seq.forEach(engine.tapCell);
    } else {
      final cells = engine.state.gridN * engine.state.gridN;
      final wrong = [for (var i = 0; i < cells; i++) i].firstWhere(
        (c) => c != seq.first,
      );
      engine.tapCell(wrong);
    }
    async.elapse(const Duration(milliseconds: 1100)); // past feedback
  }

  void playRound(CorsiEngine engine, FakeAsync async, {required bool correct}) {
    var guard = 0;
    while (engine.state.phase == GamePhase.playing && guard++ < 50) {
      playTrial(engine, async, correct: correct);
    }
  }

  test('a perfect round records the best span and persists it', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final engine = build(sink, store)..start();
      playRound(engine, async, correct: true);

      // Start span 3, 6 correct trials → climbs to a best of 5.
      expect(sink.calls, hasLength(1));
      expect(sink.calls.single.domain, 'Spatial Reasoning');
      expect(sink.calls.single.score, normalize('corsi-span', 5));
      expect(store.values[CsStoreKeys.corsiSpan], 5);
      expect(engine.state.phase, GamePhase.round);
      expect(engine.state.summary?.span, 5);
      expect(engine.state.summary?.spanDelta, isNull); // first play
    });
  });

  test('improving on the persisted best shows a positive delta', () {
    fakeAsync((async) {
      final store = FakeGameStore()..setInt(CsStoreKeys.corsiSpan, 3);
      final engine = build(FakeGameSink(), store)..start();
      playRound(engine, async, correct: true); // resumes at 3, climbs to 5
      expect(store.values[CsStoreKeys.corsiSpan], 5);
      expect(engine.state.summary?.spanDelta, 2); // 5 − 3
    });
  });

  test('a weak round lowers the stored span and shows a negative delta', () {
    fakeAsync((async) {
      // Persisted best 7; an all-wrong round recalls nothing (best 0), so the
      // stored span FALLS to 0 — the deliberate "can rise or fall" behaviour
      // that lets the dashboard show real regressions.
      final store = FakeGameStore()..setInt(CsStoreKeys.corsiSpan, 7);
      final engine = build(FakeGameSink(), store)..start();
      playRound(engine, async, correct: false);
      expect(store.values[CsStoreKeys.corsiSpan], 0);
      expect(engine.state.summary?.span, 0);
      expect(engine.state.summary?.spanDelta, -7); // 0 − 7
    });
  });

  test('resumes from the persisted best and grows the grid past span 6', () {
    fakeAsync((async) {
      final store = FakeGameStore()..setInt(CsStoreKeys.corsiSpan, 7);
      final engine = build(FakeGameSink(), store)..start();
      // Resumed at span 7 (> 6) → the grid is 5×5 from the first trial.
      expect(engine.state.level, 7);
      expect(engine.state.gridN, 5);
    });
  });

  test('two correct trials raise the span and grow the grid at 7', () {
    fakeAsync((async) {
      // Resume at span 6 (grid still 4×4); two correct → span 7 → grid 5×5.
      final store = FakeGameStore()..setInt(CsStoreKeys.corsiSpan, 6);
      final engine = build(FakeGameSink(), store)..start();
      expect(engine.state.gridN, 4);
      playTrial(engine, async, correct: true);
      playTrial(engine, async, correct: true); // 2 consecutive → span up to 7
      expect(engine.state.level, 7);
      expect(engine.state.gridN, 5);
    });
  });

  test('a correct sequence hits; a wrong cell shakes', () {
    fakeAsync((async) {
      final engine = build(FakeGameSink(), FakeGameStore())..start();
      watchSequence(engine, async).forEach(engine.tapCell);
      expect(engine.state.fb, CorsiFeedback.hit);

      async.elapse(const Duration(milliseconds: 1100));
      final seq2 = watchSequence(engine, async);
      final cells = engine.state.gridN * engine.state.gridN;
      final wrong = [
        for (var i = 0; i < cells; i++) i,
      ].firstWhere((c) => c != seq2.first);
      engine.tapCell(wrong);
      expect(engine.state.fb, CorsiFeedback.wrong);
      expect(engine.state.bad, wrong);
    });
  });

  test('runner mode calls onDone and shows no standalone summary', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final runner = FakeRunnerContext(trials: 4);
      final engine = build(sink, FakeGameStore(), runner: runner.context)
        ..start();
      playRound(engine, async, correct: true);

      expect(runner.doneCount, 1);
      expect(runner.doneScore, isNotNull);
      expect(sink.calls, hasLength(1));
      expect(engine.state.summary, isNull);
    });
  });
}
