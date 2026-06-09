import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/features/games/nback/domain/nback_engine.dart';
import 'package:cogscroll/features/games/nback/domain/nback_state.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nback_controller.g.dart';

/// Drives an [NbackEngine] and republishes its snapshots as Riverpod state.
///
/// AutoDispose: when the screen leaves the tree the engine's timers are
/// cancelled via `ref.onDispose`. The [runner] family arg is null for a
/// standalone launch, or the runner's context in baseline/session mode.
@riverpod
class NbackController extends _$NbackController {
  late final NbackEngine _engine;

  @override
  NbackState build(RunnerContext? runner) {
    _engine = NbackEngine(
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

  /// The player's "Match" input.
  void tap() => _engine.tap();
}
