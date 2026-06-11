import 'dart:math';

/// One shape-Stroop trial: the `shape` actually drawn (the correct answer),
/// the `word` naming a shape written on its plate, whether the two agree
/// (`congruent`), and the shuffled tap `options` (shape ids, including the
/// `shape`).
typedef StroopStim = ({int shape, int word, bool congruent, List<int> options});

/// Per-level difficulty parameters for Stroop (`SPEC.md` §7.1). The
/// colour-bound "more similar hues" lever becomes **shape confusability**; the
/// rest are mono-safe escalations.
typedef StroopParams = ({
  /// Tap options shown (the easy floor shows fewer; harder shows more).
  int optionCount,

  /// Response window in ms — the "presentation speed" lever as a deadline.
  /// A miss counts as incorrect with its response time set to the window.
  int windowMs,

  /// Whether the incongruent word and the distractor options are drawn from
  /// the target's *confusable* neighbours (harder to tell apart).
  bool confusable,
});

/// Number of distinct shapes (`CsShape` has six: circle…hexagon).
const int stroopShapeCount = 6;

/// Probability a trial is congruent (word names the drawn shape). Congruent
/// trials are interspersed so interference cost (incongruent − congruent RT)
/// can be measured; the prototype used ~0.35.
const double stroopCongruentRate = 0.35;

/// Mono shape-confusability map: shapes hard to tell apart at a glance, used
/// as the colour-free replacement for the prototype's "similar hues" lever.
/// circle↔hexagon, square↔diamond, triangle↔diamond; cross is distinctive.
const Map<int, List<int>> stroopConfusable = {
  0: [5], // circle ~ hexagon
  1: [3], // square ~ diamond
  2: [3], // triangle ~ diamond
  3: [1, 2], // diamond ~ square, triangle
  4: <int>[], // cross — distinctive
  5: [0], // hexagon ~ circle
};

/// Resolves the [StroopParams] for difficulty [level] (clamped to 1–5):
/// fewer→more options, slow→fast window, distinct→confusable shapes.
StroopParams stroopParamsForLevel(int level) {
  final l = level.clamp(1, 5);
  return (
    optionCount: l <= 2
        ? 3
        : l <= 4
        ? 4
        : 5,
    windowMs: switch (l) {
      1 => 3000,
      2 => 2600,
      3 => 2200,
      4 => 1800,
      _ => 1600,
    },
    confusable: l >= 4,
  );
}

/// Generates the next Stroop trial for difficulty [level]. [random] is
/// injected for determinism in tests.
StroopStim generateStroopStim(int level, Random random) {
  final params = stroopParamsForLevel(level);
  final shape = random.nextInt(stroopShapeCount);
  final congruent = random.nextDouble() < stroopCongruentRate;
  final neighbours = stroopConfusable[shape] ?? const <int>[];

  final int word;
  if (congruent) {
    word = shape;
  } else if (params.confusable && neighbours.isNotEmpty) {
    word = neighbours[random.nextInt(neighbours.length)];
  } else {
    word = _otherThan(shape, random);
  }

  final options = _buildOptions(
    correct: shape,
    count: params.optionCount,
    preferConfusable: params.confusable,
    neighbours: neighbours,
    random: random,
  );
  return (shape: shape, word: word, congruent: congruent, options: options);
}

int _otherThan(int shape, Random random) {
  int r;
  do {
    r = random.nextInt(stroopShapeCount);
  } while (r == shape);
  return r;
}

List<int> _buildOptions({
  required int correct,
  required int count,
  required bool preferConfusable,
  required List<int> neighbours,
  required Random random,
}) {
  final options = <int>[correct];
  // At confusable levels seed the distractors with the target's neighbours so
  // the choices are genuinely harder to discriminate.
  if (preferConfusable) {
    for (final n in neighbours) {
      if (options.length >= count) break;
      if (!options.contains(n)) options.add(n);
    }
  }
  while (options.length < count) {
    final r = random.nextInt(stroopShapeCount);
    if (!options.contains(r)) options.add(r);
  }
  options.shuffle(random);
  return options;
}
