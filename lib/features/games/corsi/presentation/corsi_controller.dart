import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/features/games/corsi/domain/corsi_engine.dart';
import 'package:cogscroll/features/games/corsi/domain/corsi_state.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'corsi_controller.g.dart';

/// Drives a [CorsiEngine] and republishes its snapshots as Riverpod state.
///
/// AutoDispose: when the screen leaves the tree the engine's timers are
/// cancelled via `ref.onDispose`. The [runner] family arg is null for a
/// standalone launch, or the runner's context in baseline/session mode.
@riverpod
class CorsiController extends _$CorsiController {
  late final CorsiEngine _engine;

  @override
  CorsiState build(RunnerContext? runner) {
    _engine = CorsiEngine(
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

  /// Taps cell [c] during recall.
  void tapCell(int c) => _engine.tapCell(c);
}
