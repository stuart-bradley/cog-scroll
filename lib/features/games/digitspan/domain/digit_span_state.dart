import 'package:cogscroll/core/scoring/metrics.dart' show DigitSpanMode;
import 'package:cogscroll/features/games/shared/game_engine.dart';

export 'package:cogscroll/core/scoring/metrics.dart' show DigitSpanMode;

/// The stage within a single Digit Span trial.
enum DigitSpanStage {
  /// Digits are flashing one at a time — watch.
  show,

  /// Tap the digits back on the keypad.
  recall,
}

/// The feedback motion a resolved Digit Span trial shows.
enum DigitSpanFeedback {
  /// The sequence recalled correctly — ring bloom.
  hit,

  /// A wrong sequence — shake.
  wrong,
}

/// The end-of-round summary. `spanDelta` is `best - lastBest` (null on the
/// first play); the widget maps it to a `Delta`, keeping the engine
/// Flutter-free.
typedef DigitSpanSummary = ({int span, int? spanDelta});

/// Immutable snapshot the `DigitSpanEngine` republishes to its controller.
typedef DigitSpanState = ({
  /// Current phase.
  GamePhase phase,

  /// Forward (same order) or backward (reverse order) recall.
  DigitSpanMode mode,

  /// Current trial stage.
  DigitSpanStage stage,

  /// Current sequence length (the span being tested; drives the recall slots).
  int level,

  /// Current trial index (0-based; drives the progress counter).
  int trial,

  /// Total trials this round.
  int trials,

  /// The digit currently shown (show stage), or null when blank.
  int? digit,

  /// The digits tapped so far this recall.
  List<int> input,

  /// The resolved-trial feedback, or null mid-trial.
  DigitSpanFeedback? fb,

  /// The round summary, set at finish.
  DigitSpanSummary? summary,
});
