import 'dart:math';

/// The Go shape: always the circle (shape id 0).
const int gngGoShape = 0;

/// The default No-Go shape: the square (shape id 1).
const int gngNoGoSquare = 1;

/// The L5 No-Go shape: the hexagon (shape id 5) — more visually similar to the
/// circle, so harder to discriminate at speed.
const int gngNoGoHexagon = 5;

/// Response window in ms — how long the stimulus waits for a tap before a
/// No-response resolves the trial.
const int gngDisplayMs = 720;

/// Feedback window after a resolved trial — kept near the prototype's 540 ms so
/// the game stays snappy (the per-level ISI ladder is the difficulty lever, not
/// fixed per-trial overhead). Every feedback motion (bloom, pulse, shake) is
/// sped up to [gngFeedbackMotion] so it finishes inside this window with the
/// stimulus visible (DESIGN non-negotiable) — rather than padding the window
/// out to the motions' default lengths and slowing every trial. The invariant
/// `gngFeedbackWindow >= gngFeedbackMotion` is asserted in the trial tests.
const Duration gngFeedbackWindow = Duration(milliseconds: 540);

/// The sped-up feedback-motion length passed to every Go/No-Go feedback motion
/// (bloom, pulse, shake), comfortably inside [gngFeedbackWindow] so the
/// stimulus stays visible for the whole motion.
const Duration gngFeedbackMotion = Duration(milliseconds: 460);

/// The per-level parameters for a Go/No-Go round (`SPEC.md` §7.1):
///
/// - **L1** 80/20 Go/No-Go, ISI 1000 ms.
/// - **L2** 80/20, ISI 700 ms.
/// - **L3** 70/30, ISI 600 ms.
/// - **L4** 60/40, ISI 500 ms.
/// - **L5** 60/40, ISI 400 ms, No-Go shape = hexagon (more circle-like).
typedef GngParams = ({
  /// Probability a trial is a Go.
  double goRate,

  /// Inter-stimulus interval (the blank between trials), in ms.
  int isiMs,

  /// The No-Go shape id for this level.
  int noGoShape,
});

/// Resolves the [GngParams] for difficulty [level] (clamped to 1–5).
GngParams goNoGoParamsForLevel(int level) {
  final l = level.clamp(1, 5);
  final goRate = l <= 2
      ? 0.8
      : l == 3
      ? 0.7
      : 0.6;
  const isi = [1000, 700, 600, 500, 400];
  return (
    goRate: goRate,
    isiMs: isi[l - 1],
    noGoShape: l >= 5 ? gngNoGoHexagon : gngNoGoSquare,
  );
}

/// One generated trial: its `shape` id and whether it is a Go.
typedef GngTrial = ({int shape, bool isGo});

/// Generates the next trial under [params]. [random] is injected for
/// determinism in tests.
GngTrial generateGngTrial(GngParams params, Random random) {
  final isGo = random.nextDouble() < params.goRate;
  return (shape: isGo ? gngGoShape : params.noGoShape, isGo: isGo);
}
