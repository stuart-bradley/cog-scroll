import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/entrance_fade.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/triangle.dart';
import 'package:cogscroll/core/ui_kit/wide_button.dart';
import 'package:flutter/widgets.dart';

/// Direction of a [RoundEnd] delta. [up] always means *better* — improvement
/// is shown as an upward triangle regardless of whether the underlying metric
/// rises or falls.
enum DeltaDirection {
  /// Improvement (renders an upward triangle).
  up,

  /// Regression (renders a downward triangle).
  down,
}

/// A round-over delta: a `dir`ection plus its display `text` (e.g. "+3").
typedef Delta = ({DeltaDirection dir, String text});

/// The post-round summary screen (ports `cs-core.jsx`'s `RoundEnd`).
///
/// Shows a big tabular [value] with a [caption], an optional [sub] line, an
/// optional [delta] (up = better), and an optional [levelMsg], above a continue
/// button. The content fades and rises in on first build via [EntranceFade].
class RoundEnd extends StatelessWidget {
  /// Creates a round-end screen.
  const RoundEnd({
    required this.value,
    required this.caption,
    required this.continueLabel,
    this.sub,
    this.delta,
    this.levelMsg,
    this.onContinue,
    super.key,
  });

  /// The hero metric (already formatted), e.g. "94%".
  final String value;

  /// Upper-cased caption beneath the value, e.g. "Accuracy".
  final String caption;

  /// Label for the continue button.
  final String continueLabel;

  /// Optional secondary line beneath the caption.
  final String? sub;

  /// Optional improvement/regression indicator (up = better).
  final Delta? delta;

  /// Optional level-progression message.
  final String? levelMsg;

  /// Continue handler; the button is disabled when null.
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EntranceFade(
            duration: const Duration(milliseconds: 350),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: CsType.metric),
                const SizedBox(height: 16),
                Label(caption),
                if (sub != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    sub!,
                    style: const TextStyle(
                      fontFamily: CsType.family,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: CsTokens.fg,
                    ),
                  ),
                ],
                if (delta != null) ...[
                  const SizedBox(height: 16),
                  _DeltaRow(delta!),
                ],
                if (levelMsg != null) ...[
                  const SizedBox(height: 14),
                  Label(levelMsg!, color: CsTokens.fg),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 46),
          child: WideButton(label: continueLabel, onPressed: onContinue),
        ),
      ],
    );
  }
}

/// The triangle + text row that renders a [Delta].
class _DeltaRow extends StatelessWidget {
  const _DeltaRow(this.delta);

  final Delta delta;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          key: ValueKey(delta.dir),
          size: const Size.square(11),
          painter: TrianglePainter(up: delta.dir == DeltaDirection.up),
        ),
        const SizedBox(width: 6),
        Text(
          delta.text,
          style: const TextStyle(
            fontFamily: CsType.family,
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: CsTokens.fg,
          ),
        ),
      ],
    );
  }
}
