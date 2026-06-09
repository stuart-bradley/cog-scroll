import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

/// Minimal concrete engine over an `int` snapshot to exercise the base.
class _CounterEngine extends GameEngine<int> {
  _CounterEngine({
    required super.sink,
    required super.store,
    required super.clock,
  }) : super(initial: 0);

  void bump() => emit(state + 1);

  void scheduleBump(Duration delay) => after(delay, bump);
}

void main() {
  _CounterEngine build() => _CounterEngine(
    sink: FakeGameSink(),
    store: FakeGameStore(),
    clock: FakeClock(DateTime.utc(2026)),
  );

  test('emit updates the snapshot and notifies onChange in order', () {
    final seen = <int>[];
    final engine = build()
      ..onChange = seen.add
      ..bump()
      ..bump();

    expect(engine.state, 2);
    expect(seen, [1, 2]);
  });

  test('scheduled timers fire after their delay', () {
    fakeAsync((async) {
      final engine = build()..scheduleBump(const Duration(milliseconds: 500));
      async.elapse(const Duration(milliseconds: 499));
      expect(engine.state, 0); // not yet
      async.elapse(const Duration(milliseconds: 1));
      expect(engine.state, 1);
    });
  });

  test('dispose cancels pending timers so the callback never fires', () {
    fakeAsync((async) {
      final engine = build()
        ..scheduleBump(const Duration(milliseconds: 500))
        ..dispose();
      async.elapse(const Duration(seconds: 1));
      expect(engine.state, 0); // cancelled — the stale-timer guard
    });
  });

  test('clearTimers cancels in flight but leaves the engine usable', () {
    fakeAsync((async) {
      final engine = build()
        ..scheduleBump(const Duration(milliseconds: 500))
        ..clearTimers();
      async.elapse(const Duration(seconds: 1));
      expect(engine.state, 0);
      engine.bump();
      expect(engine.state, 1);
    });
  });
}
