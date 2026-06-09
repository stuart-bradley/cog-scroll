/// An injectable source of the current wall-clock time.
///
/// Inject this instead of calling [DateTime.now] directly so time-dependent
/// behaviour — analytics timestamps now, trial expiry later — is deterministic
/// under test via [FakeClock]. (The monotonic stopwatch the reaction/trails
/// games need lands with those games in M3, growing this interface.)
//
// A deliberate injection seam with SystemClock and FakeClock implementations;
// gains a stopwatch() member in M3.
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
/// tests.
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
