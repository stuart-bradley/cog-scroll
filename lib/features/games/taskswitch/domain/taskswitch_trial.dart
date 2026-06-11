import 'dart:math';

/// The attribute a Task Switching trial is being judged on. Shape and fill are
/// the prototype's two rules; **size** is the added third mono attribute so the
/// top level can rotate three rules without colour (`SPEC.md` §7).
enum SwitchRule {
  /// Judge the shape: circle (option 0) vs square (option 1).
  shape,

  /// Judge the fill: filled (option 0) vs hollow (option 1).
  fill,

  /// Judge the size: big (option 0) vs small (option 1).
  size,
}

/// One Task Switching stimulus. `shape` is 0 (circle) or 1 (square); `filled`
/// and `big` are the other two binary attributes.
typedef SwitchStim = ({int shape, bool filled, bool big});

/// Per-level difficulty parameters (`SPEC.md` §7.1).
typedef SwitchParams = ({
  /// The rules in rotation. Levels 1–4 use shape/fill; level 5 adds size.
  List<SwitchRule> rules,

  /// Fixed switch cadence (change the rule every N trials), or null for a
  /// random switch each trial.
  int? cadence,

  /// Response window in ms — tightens at L4+.
  int windowMs,
});

/// The two-option button labels for a given [rule].
List<String> switchOptionLabels(SwitchRule rule) => switch (rule) {
  SwitchRule.shape => const ['Circle', 'Square'],
  SwitchRule.fill => const ['Filled', 'Hollow'],
  SwitchRule.size => const ['Big', 'Small'],
};

/// The correct option index (0/1) for [stim] under [rule].
int switchCorrectChoice(SwitchRule rule, SwitchStim stim) => switch (rule) {
  SwitchRule.shape => stim.shape,
  SwitchRule.fill => stim.filled ? 0 : 1,
  SwitchRule.size => stim.big ? 0 : 1,
};

/// Resolves the [SwitchParams] for difficulty [level] (clamped to 1–5).
SwitchParams switchParamsForLevel(int level) {
  final l = level.clamp(1, 5);
  return (
    rules: l >= 5
        ? const [SwitchRule.shape, SwitchRule.fill, SwitchRule.size]
        : const [SwitchRule.shape, SwitchRule.fill],
    cadence: switch (l) {
      1 => 4,
      2 => 2,
      _ => null, // L3+ switch randomly
    },
    windowMs: l >= 4 ? 1600 : 2200,
  );
}

/// Generates the next stimulus for difficulty [level]. Shape and fill always
/// vary; size only varies when it can be a rule (L5), else it stays big so an
/// un-judged dimension isn't a distraction. [random] is injected for tests.
SwitchStim generateSwitchStim(int level, Random random) {
  final rules = switchParamsForLevel(level).rules;
  final sizeIsRule = rules.contains(SwitchRule.size);
  return (
    shape: random.nextBool() ? 1 : 0,
    filled: random.nextBool(),
    // Size only varies when it can be judged (L5); otherwise it stays big.
    big: !sizeIsRule || random.nextBool(),
  );
}
