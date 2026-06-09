/// An injectable source of the current wall-clock time.
///
/// Inject this instead of calling [DateTime.now] directly so time-dependent
/// behaviour — analytics timestamps, trial expiry, and the reaction/trails
/// games' elapsed-time measurement (taken as [now] deltas) — is deterministic
/// under test via [FakeClock]. (A real `Stopwatch` is not used — it reads the
/// monotonic VM clock, which `fakeAsync` cannot control; `now()` deltas with a
/// [FakeClock] can be driven deterministically.)
//
// A deliberate injection seam with SystemClock and FakeClock implementations.
// ignore: one_member_abstracts
abstract interface class Clock {
  /// The current wall-clock time.
  DateTime now();
}

/// A [Clock] backed by the real system clock.
class SystemClock implements Clock {
  /// Creates a [SystemClock].
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A [Clock] whose time is fixed and advanced manually, for deterministic
/// tests. Game elapsed-time tests [advance] it to simulate the player reacting.
class FakeClock implements Clock {
  /// Creates a [FakeClock] anchored at the given time.
  FakeClock(this._now);

  DateTime _now;

  @override
  DateTime now() => _now;

  /// Replaces the current time with [value]. A named method rather than a
  /// setter so it can't be confused with the [now] reader.
  // ignore: use_setters_to_change_properties
  void setTime(DateTime value) => _now = value;

  /// Advances the current time by [duration].
  void advance(Duration duration) => _now = _now.add(duration);
}
