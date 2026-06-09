/// Injected into a runner-capable game when it is driven by the baseline /
/// Today-session runner (`SPEC.md` §3.5). Pure Dart (callbacks are plain
/// function types, not Flutter typedefs) so engines can hold it.
///
/// When a game has a [RunnerContext] it hides its own TopBar, runs the
/// abbreviated [trials] / [points] length, and on `finish()` calls [onDone]
/// with the normalized score instead of showing a RoundEnd. `recordResult`
/// still fires. M3 only makes games honour this; the runner itself is M5/M6.
class RunnerContext {
  /// Creates a runner context.
  const RunnerContext({
    required this.index,
    required this.total,
    required this.domain,
    required this.focus,
    required this.onDone,
    required this.onSkip,
    this.trials,
    this.points,
  });

  /// Position of this game in the runner set (for the unified header).
  final int index;

  /// Size of the runner set.
  final int total;

  /// The domain this game contributes to.
  final String domain;

  /// Whether this pick is a weak-domain focus (renders a focus dot).
  final bool focus;

  /// Called with the normalized 0–100 score when the game finishes.
  final void Function(int score) onDone;

  /// Called when the runner's Skip is used.
  final void Function() onSkip;

  /// Abbreviated trial count; null runs the full length.
  final int? trials;

  /// Abbreviated target count (Trail Making); null runs the full length.
  final int? points;
}
