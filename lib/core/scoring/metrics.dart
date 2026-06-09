/// Raw inputs for the leveled / mode-aware scoring metrics (`SPEC.md` §4.3).
///
/// Each generalises the n-back pattern (`docs/design/cs-data.jsx`): a higher
/// difficulty level lifts the effective score, so the same accuracy or time is
/// worth more when the level is harder. See `NbackRaw` for the original.
library;

/// Accuracy (`acc`, %) at a difficulty `level` — flanker, go/no-go, task switch.
typedef LevelAcc = ({int acc, int level});

/// Stroop interference cost (`interferenceMs`, lower is better) at a `level`.
typedef StroopRaw = ({int interferenceMs, int level});

/// Trail Making mode.
enum TrailMode {
  /// Numbers only, 1→N.
  a,

  /// Number/letter alternation, 1→A→2→B….
  b,
}

/// Trail Making raw: `seconds` over `count` targets in [TrailMode]. Scored on
/// seconds-per-target, so the count (the difficulty lever) cancels out and the
/// two modes use their own norm curves.
typedef TrailRaw = ({double seconds, int count, TrailMode mode});

/// Digit Span recall direction.
enum DigitSpanMode {
  /// Recall in the presented order.
  forward,

  /// Recall in reverse order.
  backward,
}

/// Digit Span raw: best `span` recalled in [DigitSpanMode] (own norm curves).
typedef DigitSpanRaw = ({int span, DigitSpanMode mode});
