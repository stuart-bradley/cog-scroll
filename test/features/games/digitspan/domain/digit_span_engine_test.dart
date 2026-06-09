import 'dart:math';

import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_engine.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_state.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fakes.dart';

void main() {
  DigitSpanEngine build(
    FakeGameSink sink,
    FakeGameStore store, {
    required DigitSpanMode mode,
    int seed = 1,
  }) => DigitSpanEngine(
    mode: mode,
    sink: sink,
    store: store,
    clock: FakeClock(DateTime.utc(2026)),
    random: Random(seed),
  );

  /// Watches the flashing digits (in order, repeats included) while elapsing to
  /// the recall stage.
  List<int> watchDigits(DigitSpanEngine engine, FakeAsync async) {
    final digits = <int>[];
    engine.onChange = (s) {
      if (s.stage == DigitSpanStage.show && s.digit != null) {
        digits.add(s.digit!);
      }
    };
    var guard = 0;
    while (engine.state.stage == DigitSpanStage.show && guard++ < 400) {
      async.elapse(const Duration(milliseconds: 80));
    }
    engine.onChange = null;
    return digits;
  }

  /// Recall [digits] on the keypad, then clear the feedback window.
  void recall(DigitSpanEngine engine, FakeAsync async, List<int> digits) {
    digits.forEach(engine.pad);
    async.elapse(const Duration(milliseconds: 1000)); // past feedback (950)
  }

  void playRound(
    DigitSpanEngine engine,
    FakeAsync async, {
    required bool correct,
  }) {
    var guard = 0;
    while (engine.state.phase == GamePhase.playing && guard++ < 50) {
      final shown = watchDigits(engine, async);
      final target = engine.mode == DigitSpanMode.forward
          ? shown
          : shown.reversed.toList();
      final input = correct
          ? target
          : ([...target]..[0] = (target.first + 1) % 10);
      recall(engine, async, input);
    }
  }

  test('a perfect forward round records the mode-aware score and persists', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final engine = build(sink, store, mode: DigitSpanMode.forward)..start();
      playRound(engine, async, correct: true);

      // Start span 4, 6 correct → best 6.
      expect(sink.calls.single.domain, 'Working Memory');
      expect(
        sink.calls.single.score,
        normalize('digit-span', (span: 6, mode: DigitSpanMode.forward)),
      );
      expect(store.values[CsStoreKeys.digitSpanFwd], 6);
      expect(engine.state.summary?.span, 6);
      expect(engine.state.summary?.spanDelta, isNull); // first play
    });
  });

  test('a perfect backward round recalls in reverse and persists its key', () {
    fakeAsync((async) {
      final sink = FakeGameSink();
      final store = FakeGameStore();
      final engine = build(sink, store, mode: DigitSpanMode.backward)..start();
      playRound(engine, async, correct: true);

      // Start span 3, 6 correct → best 5.
      expect(
        sink.calls.single.score,
        normalize('digit-span', (span: 5, mode: DigitSpanMode.backward)),
      );
      expect(store.values[CsStoreKeys.digitSpanBwd], 5);
      expect(store.values[CsStoreKeys.digitSpanFwd], isNull); // separate key
      expect(engine.state.summary?.span, 5);
    });
  });

  test('backward mode requires the reverse order (same order is wrong)', () {
    fakeAsync((async) {
      final engine = build(
        FakeGameSink(),
        FakeGameStore(),
        mode: DigitSpanMode.backward,
        seed: 2,
      )..start();
      final shown = watchDigits(engine, async);
      // The seed yields a non-palindrome — the shown order is the wrong answer.
      expect(shown, isNot(shown.reversed.toList()));
      shown.forEach(engine.pad);
      expect(engine.state.fb, DigitSpanFeedback.wrong);
    });
  });

  test('forward mode accepts the shown order (a hit)', () {
    fakeAsync((async) {
      final engine = build(
        FakeGameSink(),
        FakeGameStore(),
        mode: DigitSpanMode.forward,
        seed: 2,
      )..start();
      watchDigits(engine, async).forEach(engine.pad);
      expect(engine.state.fb, DigitSpanFeedback.hit);
    });
  });

  test('eases the span down on consecutive failures, clamped at the floor', () {
    fakeAsync((async) {
      // Resume above the floor (5) so the decrement path actually runs: an
      // all-wrong round steps the level 5 → 4 → 3 and then holds at the
      // forward floor of 3.
      final store = FakeGameStore()..setInt(CsStoreKeys.digitSpanFwd, 5);
      final engine = build(FakeGameSink(), store, mode: DigitSpanMode.forward)
        ..start();
      playRound(engine, async, correct: false);
      expect(engine.state.level, 3); // eased from 5, clamped at the floor
      expect(engine.state.summary?.span, 0); // nothing recalled
      expect(store.values[CsStoreKeys.digitSpanFwd], 0);
      expect(engine.state.summary?.spanDelta, -5); // 0 − 5
    });
  });
}
