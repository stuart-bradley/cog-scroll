import 'package:cogscroll/features/games/shared/game_engine.dart';

/// The feedback motion a resolved Go/No-Go trial shows.
enum GngFeedback {
  /// Correct tap on a Go (circle) — ring bloom.
  correctGo,

  /// Correct withhold on a No-Go (square/hexagon) — square pulse.
  correctWithhold,

  /// Wrong response (tapped a No-Go, or missed a Go) — shake.
  wrong,
}

/// The end-of-round summary. `accDelta` is `acc - lastAcc` (null on the first
/// round); the widget maps it to a `Delta`, keeping the engine Flutter-free.
typedef GngSummary = ({int acc, int playedLevel, int? accDelta});

/// Immutable snapshot the `GoNoGoEngine` republishes to its controller.
typedef GngState = ({
  /// Current phase.
  GamePhase phase,

  /// Current difficulty level (1–5; drives the chrome label + intro).
  int level,

  /// Trial count for this round.
  int round,

  /// Current trial index (0-based); drives progress + the countdown key.
  int idx,

  /// The shape on screen (0 circle = Go; 1 square / 5 hexagon = No-Go), or null
  /// when blank between trials.
  int? shape,

  /// Whether the stimulus is shown (stays true through the feedback motion).
  bool showing,

  /// The resolved-trial feedback, or null mid-trial.
  GngFeedback? fb,

  /// The round summary, set at finish in standalone mode.
  GngSummary? summary,

  /// Optional level-up / eased message for the round screen.
  String? levelMsg,
});
