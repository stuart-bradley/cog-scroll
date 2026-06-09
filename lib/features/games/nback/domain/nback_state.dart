import 'package:cogscroll/features/games/shared/game_engine.dart';

/// The feedback motion a resolved n-back trial shows. A correct *rejection*
/// (correctly withholding on a non-match) shows none, so this is nullable.
enum NbackFeedback {
  /// Correct tap on a match — ring bloom.
  hit,

  /// Wrong tap or a missed match — shake.
  wrong,
}

/// The end-of-round summary. `accDelta` is `acc - lastAcc` (null on the first
/// round); the widget maps it to a `Delta`, keeping the engine Flutter-free.
typedef NbackSummary = ({int acc, int playedN, int? accDelta});

/// Immutable snapshot the `NbackEngine` republishes to its controller.
typedef NbackState = ({
  /// Current phase.
  GamePhase phase,

  /// Current difficulty level N (drives the chrome label + intro text).
  int n,

  /// Trial count for this round (engine-owned; drives progress + footnotes).
  int round,

  /// Current trial index (0-based; drives the progress counter).
  int idx,

  /// The shape on screen (0–5), or null when blank between trials.
  int? shape,

  /// Whether the stimulus is shown (stays true through feedback motion).
  bool showing,

  /// The resolved-trial feedback, or null (mid-trial or correct rejection).
  NbackFeedback? fb,

  /// The round summary, set at finish in standalone mode.
  NbackSummary? summary,

  /// Optional level-up / eased message for the round screen.
  String? levelMsg,
});
