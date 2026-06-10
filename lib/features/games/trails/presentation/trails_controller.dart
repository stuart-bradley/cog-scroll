import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/trails/domain/trails_engine.dart';
import 'package:cogscroll/features/games/trails/domain/trails_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trails_controller.g.dart';

/// Drives a [TrailsEngine] and republishes its snapshots as Riverpod state.
///
/// Family-keyed by [TrailMode] (A: numbers / B: number-letter alternation) —
/// the two `GameRegistry` entries backed by this one engine — and by the
/// [runner] context (null for a standalone launch). AutoDispose cancels the
/// engine's timers via `ref.onDispose` when the screen leaves.
@riverpod
class TrailsController extends _$TrailsController {
  late final TrailsEngine _engine;

  @override
  TrailsState build(TrailMode mode, RunnerContext? runner) {
    _engine = TrailsEngine(
      mode: mode,
      sink: ref.watch(gameSinkProvider),
      store: ref.watch(gameStoreProvider),
      clock: ref.watch(clockProvider),
      runner: runner,
      timers: ref.watch(timersProvider),
    )..onChange = (snapshot) => state = snapshot;
    ref.onDispose(_engine.dispose);
    return _engine.state;
  }

  /// Begins a round (from the intro, or a new round after a standalone end).
  void start() => _engine.start();

  /// Taps the target at sequence [index].
  void tap(int index) => _engine.tap(index);
}
