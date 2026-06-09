import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// A tracked, upper-cased micro-label used throughout CogScroll's chrome
/// (ports `cs-core.jsx`'s `Label`).
///
/// Renders [text] in upper case at weight 600 with 0.22em tracking on a single
/// line. This is intentionally heavier than [CsType.microLabel] (weight 500),
/// so the style is built inline rather than reusing that theme token.
class Label extends StatelessWidget {
  /// Creates a micro-label rendering [text] at [size] in [color].
  const Label(
    this.text, {
    this.size = 12,
    this.color = CsTokens.sub,
    super.key,
  });

  /// The label content; always rendered upper-cased.
  final String text;

  /// Font size in logical pixels; tracking is 0.22em of this value.
  final double size;

  /// Text colour — defaults to secondary ink.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      softWrap: false,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: TextStyle(
        fontFamily: CsType.family,
        fontWeight: FontWeight.w600,
        fontSize: size,
        height: 1,
        letterSpacing: size * 0.22,
        color: color,
      ),
    );
  }
}
