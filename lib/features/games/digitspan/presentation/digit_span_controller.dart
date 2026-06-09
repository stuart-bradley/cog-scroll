import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_engine.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_state.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'digit_span_controller.g.dart';

/// Drives a [DigitSpanEngine] and republishes its snapshots as Riverpod state.
///
/// Catalog-only: family-keyed by [DigitSpanMode] (forward / backward), never by
/// a runner — Digit Span is not runner-capable (`SPEC.md` §7). AutoDispose
/// cancels the engine's timers via `ref.onDispose` when the screen leaves.
@riverpod
class DigitSpanController extends _$DigitSpanController {
  late final DigitSpanEngine _engine;

  @override
  DigitSpanState build(DigitSpanMode mode) {
    _engine = DigitSpanEngine(
      mode: mode,
      sink: ref.watch(gameSinkProvider),
      store: ref.watch(gameStoreProvider),
      clock: ref.watch(clockProvider),
      timers: ref.watch(timersProvider),
    )..onChange = (snapshot) => state = snapshot;
    ref.onDispose(_engine.dispose);
    return _engine.state;
  }

  /// Begins a round (from the intro, or a new round after a standalone end).
  void start() => _engine.start();

  /// Taps digit [d] on the keypad during recall.
  void pad(int d) => _engine.pad(d);
}
