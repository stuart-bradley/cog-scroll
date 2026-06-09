/// Two adaptive-difficulty staircases shared across the games (`SPEC.md` §7).
///
/// [LevelStaircase] — the uniform across-play rule for leveled games: +1 level
/// after two consecutive rounds above the up-threshold, −1 after two below.
/// [SpanStaircase] — the within-play ±1 rule for span games (Corsi, DigitSpan).
library;

/// Across-play difficulty level on a two-consecutive-rounds ±1 staircase.
///
/// One round produces a metric; [recordRound] folds it in and may step [level]
/// by ±1 (clamped to `[min, max]`) once [streak] reaches [streakNeeded] in a
/// direction. [level] and [streak] are persisted between plays. Set
/// [lowerIsBetter] for time / interference metrics where a smaller value is up.
class LevelStaircase {
  /// Creates a staircase. [level]/[streak] are typically loaded from storage.
  LevelStaircase({
    required this.level,
    required this.min,
    required this.max,
    required this.upThreshold,
    required this.downThreshold,
    this.streak = 0,
    this.streakNeeded = 2,
    this.lowerIsBetter = false,
  });

  /// Current difficulty level (clamped to `[min, max]`).
  int level;

  /// Signed run of consecutive qualifying rounds: positive = ups, negative =
  /// downs. Reset to 0 on a non-qualifying round or after a level change.
  int streak;

  /// Lower / upper level bounds.
  final int min;

  /// Upper level bound.
  final int max;

  /// A round qualifies "up" when its metric beats this; "down" when worse than
  /// [downThreshold]. Direction respects [lowerIsBetter].
  final num upThreshold;

  /// See [upThreshold].
  final num downThreshold;

  /// Consecutive qualifying rounds needed to change a level (default 2).
  final int streakNeeded;

  /// When true, a *smaller* metric is better (time, interference).
  final bool lowerIsBetter;

  /// Folds one round's [metric] into the staircase. Returns the level change
  /// applied: `+1`, `-1`, or `0`.
  int recordRound(num metric) {
    final up = lowerIsBetter ? metric < upThreshold : metric > upThreshold;
    final down = lowerIsBetter
        ? metric > downThreshold
        : metric < downThreshold;
    if (up) {
      streak = streak > 0 ? streak + 1 : 1;
    } else if (down) {
      streak = streak < 0 ? streak - 1 : -1;
    } else {
      streak = 0;
    }
    if (streak >= streakNeeded) {
      streak = 0;
      if (level < max) {
        level++;
        return 1;
      }
    } else if (streak <= -streakNeeded) {
      streak = 0;
      if (level > min) {
        level--;
        return -1;
      }
    }
    return 0;
  }
}

/// Within-play span staircase: +1 span after two consecutive correct trials,
/// −1 after two consecutive failures (never below [minSpan]); tracks [best].
class SpanStaircase {
  /// Creates a span staircase at [level], persisted between plays; [best] is
  /// the longest span successfully recalled so far.
  SpanStaircase({required this.level, required this.minSpan, this.best = 0});

  /// Current sequence length.
  int level;

  /// Floor for [level] (forward digit span 3, backward 2, corsi 2).
  final int minSpan;

  /// Longest span recalled correctly.
  int best;

  int _cc = 0;
  int _cf = 0;

  /// Folds one trial's outcome in: advances best/length on success, eases on
  /// two consecutive failures.
  void recordTrial({required bool correct}) {
    if (correct) {
      if (level > best) best = level;
      _cc++;
      _cf = 0;
      if (_cc >= 2) {
        level++;
        _cc = 0;
      }
    } else {
      _cf++;
      _cc = 0;
      if (_cf >= 2 && level > minSpan) {
        level--;
        _cf = 0;
      }
    }
  }
}
