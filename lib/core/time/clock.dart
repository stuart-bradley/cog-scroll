/// An injectable source of time: the current wall-clock instant and a monotonic
/// stopwatch.
///
/// Inject this instead of calling [DateTime.now] or `Stopwatch()` directly so
/// time-dependent behaviour — analytics timestamps, trial expiry, and the
/// reaction/trails/stroop games' elapsed-time measurement — is deterministic
/// under test: [FakeClock] fixes [now], and a `fakeAsync` zone (which both
/// engine and widget tests run in) drives the [stopwatch].
abstract interface class Clock {
  /// The current wall-clock time.
  DateTime now();

  /// A fresh, stopped [Stopwatch]. Inside a `fakeAsync` zone it is driven by
  /// the fake clock, so games' elapsed-time measurement is deterministic.
  Stopwatch stopwatch();
}

/// A [Clock] backed by the real system clock.
class SystemClock implements Clock {
  /// Creates a [SystemClock].
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  Stopwatch stopwatch() => Stopwatch();
}

/// A [Clock] whose [now] is fixed and advanced manually, for deterministic
/// tests. Its [stopwatch] is a real [Stopwatch]; drive elapsed time within a
/// `fakeAsync` zone.
class FakeClock implements Clock {
  /// Creates a [FakeClock] anchored at the given time.
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  @override
  Stopwatch stopwatch() => Stopwatch();

  /// Replaces the current time with [value]. A named method rather than a
  /// setter so it can't be confused with the [now] reader.
  // ignore: use_setters_to_change_properties
  void setTime(DateTime value) => _now = value;

  /// Advances the current time by [duration].
  void advance(Duration duration) => _now = _now.add(duration);
}
