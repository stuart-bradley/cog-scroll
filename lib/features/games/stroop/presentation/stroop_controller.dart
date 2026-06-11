import 'package:cogscroll/core/time/clock_provider.dart';
import 'package:cogscroll/features/games/shared/game_sink.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_engine.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stroop_controller.g.dart';

/// Drives a [StroopEngine] and republishes its snapshots as Riverpod state.
///
/// Catalog-only: never family-keyed by a runner — Stroop is not runner-capable
/// (`SPEC.md` §7). AutoDispose cancels the engine's timers via `ref.onDispose`
/// when the screen leaves.
@riverpod
class StroopController extends _$StroopController {
  late final StroopEngine _engine;

  @override
  StroopState build() {
    _engine = StroopEngine(
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

  /// Taps the shape [shapeId] from the options.
  void pick(int shapeId) => _engine.pick(shapeId);
}
