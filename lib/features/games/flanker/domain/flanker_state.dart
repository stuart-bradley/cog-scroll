import 'package:cogscroll/features/games/shared/game_engine.dart';

/// The direction the target (and the response) points.
enum FlankerDir {
  /// Pointing left.
  left,

  /// Pointing right.
  right,
}

/// The opposite of [dir] — the incongruent flanker direction.
FlankerDir flipDir(FlankerDir dir) =>
    dir == FlankerDir.left ? FlankerDir.right : FlankerDir.left;

/// One generated trial: the target's direction and whether the flankers are
/// congruent (point the same way). The correct response is always `dir`,
/// regardless of congruency — congruency only changes how the flankers look.
typedef FlankerStim = ({FlankerDir dir, bool congruent});

/// The feedback motion a resolved Flanker trial shows. A correct answer drives
/// a directional surge; a wrong answer (or a timeout) shakes.
enum FlankerFeedback {
  /// Correct response — directional surge toward the answer.
  hit,

  /// Wrong response or a missed deadline — shake.
  wrong,
}

/// The end-of-round summary. `accDelta` is `acc - lastAcc` (null on the first
/// round); the widget maps it to a `Delta`, keeping the engine Flutter-free.
typedef FlankerSummary = ({int acc, int playedLevel, int? accDelta});

/// Immutable snapshot the `FlankerEngine` republishes to its controller.
typedef FlankerState = ({
  /// Current phase.
  GamePhase phase,

  /// Current difficulty level (1–5; drives the chrome label, intro, and the
  /// per-level display params via `flankerParamsForLevel`).
  int level,

  /// Trial count for this round (engine-owned; drives progress + footnotes).
  int round,

  /// Current trial index (0-based); drives progress + the countdown key.
  int idx,

  /// The current trial (target direction + congruency), or null when blank
  /// between trials.
  FlankerStim? stim,

  /// The resolved-trial feedback, or null mid-trial.
  FlankerFeedback? fb,

  /// The round summary, set at finish in standalone mode.
  FlankerSummary? summary,

  /// Optional level-up / eased message for the round screen.
  String? levelMsg,
});
