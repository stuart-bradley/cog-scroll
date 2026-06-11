import 'dart:math';

import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_engine.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_state.dart';
import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_trial.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  TaskSwitchEngine build(
    FakeGameSink sink,
    FakeGameStore store, {
    int round = 8,
    int seed = 1,
  }) => TaskSwitchEngine(
    sink: sink,
    store: store,
    clock: FakeClock(DateTime.utc(2026)),
    round: round,
    random: Random(seed),
  );

  /// Plays a full round, tapping the active rule's correct option (or the
  /// wrong one when [correct] is false). Returns the active rule per trial idx.
  Map<int, SwitchRule> playRound(
    TaskSwitchEngine engine,
    FakeAsync async, {
    bool correct = true,
  }) {
    final rules = <int, SwitchRule>{};
    engine.start();
    var guard = 0;
    while (engine.state.phase == GamePhase.playing && guard++ < 2000) {
      final st = engine.state;
      final stim = st.stim;
      if (st.fb == null && stim != null && !rules.containsKey(st.idx)) {
        rules[st.idx] = st.rule;
        final right = switchCorrectChoice(st.rule, stim);
        engine.pick(correct ? right : 1 - right);
        async.elapse(taskSwitchFeedback + const Duration(milliseconds: 20));
      } else {
        async.elapse(const Duration(milliseconds: 20));
      }
    }
    return rules;
  }

  test('a perfect round records switch-acc and persists state', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final engine = build(sink, store);
      playRound(engine, async);

      expect(sink.calls, hasLength(1));
      expect(sink.calls.single.domain, 'Mental Flexibility');
      expect(
        sink.calls.single.score,
        normalize('switch-acc', (acc: 100, level: 1)),
      );
      expect(store.values[CsStoreKeys.switchAcc], 100);
      expect(store.values[CsStoreKeys.switchLevel], 1);
      expect(store.values[CsStoreKeys.switchStreak], 1);
      expect(engine.state.summary?.acc, 100);
      expect(engine.state.summary?.playedLevel, 1);
    });
  });

  test('judging the wrong option every trial scores zero', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final engine = build(FakeGameSink(), store);
      playRound(engine, async, correct: false);
      expect(store.values[CsStoreKeys.switchAcc], 0);
    });
  });

  test('L1 changes the rule every four trials', () {
    fakeAsync((async) {
      // Default round is 8 — two runs of four around a single switch.
      final engine = build(FakeGameSink(), FakeGameStore());
      final rules = playRound(engine, async);
      expect(rules[0], rules[1]);
      expect(rules[1], rules[2]);
      expect(rules[2], rules[3]);
      expect(rules[4], isNot(rules[3])); // switched at trial 4
      expect(rules[4], rules[5]);
      expect(rules[5], rules[6]);
      expect(rules[6], rules[7]);
    });
  });

  test('L2 changes the rule every two trials', () {
    fakeAsync((async) {
      final store = FakeGameStore()..setInt(CsStoreKeys.switchLevel, 2);
      final engine = build(FakeGameSink(), store, round: 6);
      final rules = playRound(engine, async);
      expect(rules[0], rules[1]);
      expect(rules[2], isNot(rules[1]));
      expect(rules[2], rules[3]);
      expect(rules[4], isNot(rules[3]));
    });
  });

  test('L5 rotates three rules including size, judged correctly', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore()..setInt(CsStoreKeys.switchLevel, 5);
      final engine = build(sink, store, round: 20, seed: 7);
      final rules = playRound(engine, async);
      // Size joins the rotation at L5, and tapping its correct option still
      // scores — proving the size-rule resolution path.
      expect(rules.values, contains(SwitchRule.size));
      expect(store.values[CsStoreKeys.switchAcc], 100);
    });
  });

  test('a correct tap blooms, a wrong tap shakes', () {
    fakeAsync((async) {
      final fbs = <int, SwitchFeedback>{};
      final engine = build(FakeGameSink(), FakeGameStore(), round: 4)
        ..onChange = (s) {
          if (s.fb != null && s.phase == GamePhase.playing) fbs[s.idx] = s.fb!;
        }
        ..start();
      var guard = 0;
      final seen = <int>{};
      while (engine.state.phase == GamePhase.playing && guard++ < 500) {
        final st = engine.state;
        final stim = st.stim;
        if (st.fb == null && stim != null && !seen.contains(st.idx)) {
          seen.add(st.idx);
          final right = switchCorrectChoice(st.rule, stim);
          engine.pick(st.idx.isEven ? right : 1 - right);
          async.elapse(taskSwitchFeedback + const Duration(milliseconds: 20));
        } else {
          async.elapse(const Duration(milliseconds: 20));
        }
      }
      expect(fbs[0], SwitchFeedback.hit);
      expect(fbs[1], SwitchFeedback.wrong);
      expect(fbs[2], SwitchFeedback.hit);
      expect(fbs[3], SwitchFeedback.wrong);
    });
  });

  test('a missed response deadline counts as wrong', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final engine = build(FakeGameSink(), store, round: 2)..start();
      async.elapse(const Duration(seconds: 12)); // never respond
      expect(store.values[CsStoreKeys.switchAcc], 0);
      expect(engine.state.phase, GamePhase.round);
    });
  });

  test('two perfect rounds level up (1 → 2)', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final engine = build(FakeGameSink(), store);
      playRound(engine, async); // streak 1
      playRound(engine, async); // streak 2 → up
      expect(store.values[CsStoreKeys.switchLevel], 2);
      expect(store.values[CsStoreKeys.switchStreak], 0);
      expect(engine.state.levelMsg, contains('Level up'));
    });
  });

  test('two failed rounds ease the level down (2 → 1)', () {
    fakeAsync((async) {
      final store = FakeGameStore()..setInt(CsStoreKeys.switchLevel, 2);
      final engine = build(FakeGameSink(), store);
      playRound(engine, async, correct: false);
      playRound(engine, async, correct: false);
      expect(store.values[CsStoreKeys.switchLevel], 1);
      expect(engine.state.levelMsg, contains('Eased'));
    });
  });

  test('the second-play delta is accuracy vs the persisted last', () {
    fakeAsync((async) {
      final store = FakeGameStore();
      final engine = build(FakeGameSink(), store);
      playRound(engine, async); // acc 100, stored
      playRound(engine, async, correct: false); // acc 0
      expect(engine.state.summary?.accDelta, -100);
    });
  });
}
