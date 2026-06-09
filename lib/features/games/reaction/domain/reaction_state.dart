import 'package:cogscroll/features/games/shared/game_engine.dart';

/// The stage within a single reaction trial.
enum ReactionStage {
  /// Blank — waiting for the stimulus (a tap here is "too soon").
  wait,

  /// Stimulus shown — tap as fast as possible.
  ready,

  /// The measured reaction time is displayed.
  result,

  /// The player jumped the gun; the trial restarts.
  tooSoon,
}

/// End-of-round summary. `previous` is the last round's average (null on the
/// first round); the widget turns it into a faster/slower `Delta`.
typedef ReactionSummary = ({int avg, int best, int? previous});

/// Immutable snapshot the `ReactionEngine` republishes to its controller.
typedef ReactionState = ({
  /// Current phase.
  GamePhase phase,

  /// Current trial stage.
  ReactionStage stage,

  /// The just-measured reaction time (ms), shown in [ReactionStage.result].
  int? ms,

  /// Completed-trial count (0-based; drives the `n/total` chrome).
  int trial,

  /// Total trials this round.
  int total,

  /// The round summary, set at finish in standalone mode.
  ReactionSummary? summary,
});
