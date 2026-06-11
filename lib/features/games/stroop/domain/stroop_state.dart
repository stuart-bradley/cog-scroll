import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/stroop/domain/stroop_trial.dart';

export 'package:cogscroll/features/games/stroop/domain/stroop_trial.dart'
    show StroopStim;

/// The feedback motion a resolved Stroop trial shows.
enum StroopFeedback {
  /// Tapped the shape that was drawn — ring bloom.
  hit,

  /// Tapped a wrong shape (or let the window lapse) — shake.
  wrong,
}

/// The end-of-round summary. `interferenceMs` is the round's interference cost
/// (mean incongruent RT − mean congruent RT, ms; lower is better);
/// `interferenceDelta` is this round minus the last (negative = improved, null
/// on the first play). The widget maps the delta to a `Delta`.
typedef StroopSummary = ({
  int interferenceMs,
  int playedLevel,
  int? interferenceDelta,
});

/// Immutable snapshot the `StroopEngine` republishes to its controller.
typedef StroopState = ({
  /// Current phase.
  GamePhase phase,

  /// Current difficulty level (1–5).
  int level,

  /// Current trial index (0-based; drives the progress counter).
  int idx,

  /// Total trials this round.
  int round,

  /// The current stimulus (shape drawn + word on the plate + options), or null
  /// before the first trial / after the round.
  StroopStim? stim,

  /// The shape id the player tapped this trial, or null mid-trial.
  int? picked,

  /// The resolved-trial feedback, or null mid-trial.
  StroopFeedback? fb,

  /// The round summary, set at finish.
  StroopSummary? summary,

  /// Level-up / eased-down message for the RoundEnd, or null.
  String? levelMsg,
});
