import 'package:cogscroll/features/games/shared/game_engine.dart';

/// The stage within a single Corsi trial.
enum CorsiStage {
  /// The sequence is flashing — watch.
  show,

  /// Tap the cells back in order.
  recall,
}

/// The feedback motion a resolved Corsi trial shows.
enum CorsiFeedback {
  /// Whole sequence recalled — square pulse over the grid.
  hit,

  /// A wrong cell — shake.
  wrong,
}

/// The end-of-round summary. `spanDelta` is `best - lastBest` (null on the
/// first play); the widget maps it to a `Delta`, keeping the engine pure.
typedef CorsiSummary = ({int span, int? spanDelta});

/// Immutable snapshot the `CorsiEngine` republishes to its controller.
typedef CorsiState = ({
  /// Current phase.
  GamePhase phase,

  /// Current trial stage.
  CorsiStage stage,

  /// Grid side length (4 normally; grows to 5 once the span exceeds 6).
  int gridN,

  /// Current sequence length (the span being tested).
  int level,

  /// Current trial index (0-based); drives the progress counter.
  int trial,

  /// Total trials this round.
  int trials,

  /// The cell currently lit (during show) or just tapped, or -1 for none.
  int lit,

  /// Cells tapped so far this recall (rendered filled).
  List<int> taps,

  /// The wrong cell to mark with a cross, or -1 for none.
  int bad,

  /// The resolved-trial feedback, or null mid-trial.
  CorsiFeedback? fb,

  /// The round summary, set at finish in standalone mode.
  CorsiSummary? summary,
});
