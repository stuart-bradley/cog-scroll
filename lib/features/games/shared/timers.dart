import 'dart:async';

/// Schedules cancellable delayed callbacks for a game engine.
///
/// Injected (rather than calling `Timer` directly) so timing is controllable in
/// tests; a `fakeAsync` zone drives [RealTimers]. The engine base tracks and
/// cancels every timer it schedules on dispose.
// ignore: one_member_abstracts
abstract interface class Timers {
  /// Runs [callback] once after [duration]; the returned [Timer] can cancel it.
  Timer after(Duration duration, void Function() callback);
}

/// [Timers] backed by real `dart:async` timers (fake-driven under `fakeAsync`).
class RealTimers implements Timers {
  /// Creates a [RealTimers].
  const RealTimers();

  @override
  Timer after(Duration duration, void Function() callback) =>
      Timer(duration, callback);
}
