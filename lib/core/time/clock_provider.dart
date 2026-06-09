import 'package:cogscroll/core/time/clock.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clock_provider.g.dart';

/// Provides the app-wide [Clock].
///
/// Defaults to [SystemClock]; tests override with a [FakeClock] via
/// `clockProvider.overrideWithValue(...)`. Kept alive so every consumer shares
/// one clock instance.
@Riverpod(keepAlive: true)
Clock clock(Ref ref) => const SystemClock();
