import 'dart:async';

import 'package:cogscroll/core/time/clock.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/shared/timers.dart';

/// The three phases every game moves through (`SPEC.md` §3.4).
enum GamePhase {
  /// The calm start screen.
  intro,

  /// Active play.
  playing,

  /// The post-round summary (standalone) or runner hand-off.
  round,
}

/// Records a result to the analytics layer. Injected so the pure engine never
/// imports `AnalyticsService`; a fake backs it in tests.
// ignore: one_member_abstracts
abstract interface class GameSink {
  /// Records [score] (0–100) against [domain].
  Future<void> recordResult(String domain, int score);
}

/// Synchronous per-game persistence the engine reads on `start` and writes on
/// `finish`. Backed by `CsStore` in the app, a `Map` fake in tests. Writes are
/// fire-and-forget, mirroring the prototype's synchronous `CS.store.set`.
abstract interface class GameStore {
  /// Reads [key] as an int, or null when absent.
  int? getInt(String key);

  /// Reads [key] as a double, or null when absent.
  double? getDouble(String key);

  /// Reads [key] as a String, or null when absent.
  String? getString(String key);

  /// Writes [value] under [key].
  void setInt(String key, int value);

  /// Writes [value] under [key].
  void setDouble(String key, double value);

  /// Writes [value] under [key].
  void setString(String key, String value);
}

/// Base for a pure-Dart game engine over an immutable snapshot [S].
///
/// Owns the timer list and the change seam; subclasses add the trial loop and
/// `start` / `<input>` / `finish` methods. No Flutter imports — the engine is
/// unit-testable in isolation (a `fakeAsync` zone drives [timers] and the
/// [clock]'s stopwatch). The controller assigns [onChange] to republish
/// [state].
abstract class GameEngine<S> {
  /// Creates an engine seeded with the [initial] snapshot.
  GameEngine({
    required this.sink,
    required this.store,
    required this.clock,
    required S initial,
    this.runner,
    this.timers = const RealTimers(),
  }) : _state = initial;

  /// Analytics sink for `recordResult`.
  final GameSink sink;

  /// Synchronous per-game persistence (level / streak / last-metric).
  final GameStore store;

  /// Time source (`now` + monotonic `stopwatch`).
  final Clock clock;

  /// Runner context when driven by the baseline/session runner, else null.
  final RunnerContext? runner;

  /// Timer factory (real in app, fake-driven under `fakeAsync`).
  final Timers timers;

  final List<Timer> _timers = [];

  S _state;

  /// Called with every new snapshot. Set by the controller.
  void Function(S snapshot)? onChange;

  /// The current immutable snapshot.
  S get state => _state;

  /// Publishes [next] as the current snapshot and notifies [onChange].
  void emit(S next) {
    _state = next;
    onChange?.call(next);
  }

  /// Schedules [fn] after [duration], tracked for cancellation.
  void after(Duration duration, void Function() fn) {
    _timers.add(timers.after(duration, fn));
  }

  /// Cancels every pending timer.
  void clearTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  /// Cancels timers; called from the controller's `ref.onDispose`.
  void dispose() => clearTimers();
}
