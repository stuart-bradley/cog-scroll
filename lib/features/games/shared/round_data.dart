import 'package:cogscroll/core/ui_kit/round_end.dart' show Delta;

/// The end-of-round summary a game maps its result into; `GameScaffold` feeds
/// it to the shared `RoundEnd`. The continue label + handler are supplied by
/// the scaffold (continuing advances the phase), so they are not part of this
/// data.
typedef RoundData = ({
  /// Hero metric, already formatted (e.g. "94%", "247ms").
  String value,

  /// Upper-cased caption beneath the value (e.g. "Accuracy").
  String caption,

  /// Optional secondary line.
  String? sub,

  /// Optional improvement/regression delta (up = better).
  Delta? delta,

  /// Optional level-progression message.
  String? levelMsg,
});
