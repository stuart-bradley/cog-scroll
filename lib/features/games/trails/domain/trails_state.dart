import 'package:cogscroll/core/scoring/metrics.dart' show TrailMode;
import 'package:cogscroll/features/games/shared/game_engine.dart';

export 'package:cogscroll/core/scoring/metrics.dart' show TrailMode;

/// One labelled dot on the virtual trail board (`x`, `y` are its centre on
/// the `trailBoardW × trailBoardH` surface).
typedef TrailTarget = ({double x, double y, String label});

/// The end-of-round summary. `paceDelta` is this round's seconds-per-target
/// minus the last round's (negative = faster; null on the first play). Pace,
/// not raw seconds, so the delta stays apples-to-apples when a level change
/// alters the target count. The widget maps it to a `Delta`, keeping the
/// engine Flutter-free.
typedef TrailsSummary = ({
  double seconds,
  int count,
  int playedLevel,
  double? paceDelta,
});

/// Immutable snapshot the `TrailsEngine` republishes to its controller.
typedef TrailsState = ({
  /// Current phase.
  GamePhase phase,

  /// Mode A (numbers 1→N) or Mode B (number/letter alternation).
  TrailMode mode,

  /// Current difficulty level (1–5; drives the target count and dot size).
  int level,

  /// Targets this round (the count is the §7.1 difficulty lever).
  int count,

  /// The laid-out targets, in tap order (index = sequence position).
  List<TrailTarget> targets,

  /// Index of the next target to tap; targets below it are done (filled).
  int next,

  /// Index of a briefly shake-flashed wrong tap, or null.
  int? bad,

  /// Elapsed seconds, ticking for the TopBar readout.
  double elapsed,

  /// The round summary, set at finish.
  TrailsSummary? summary,

  /// Level-up / eased-down message for the RoundEnd, or null.
  String? levelMsg,
});
