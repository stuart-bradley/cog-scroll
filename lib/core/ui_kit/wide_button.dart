import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/icons.dart';
import 'package:flutter/widgets.dart';

/// Fill style for a [WideButton].
enum WideButtonVariant {
  /// Ink fill with a white label (the primary action).
  solid,

  /// White fill with a 1.6px ink border and ink label.
  hollow,
}

/// Optional leading glyph for a [WideButton].
enum WideButtonIcon {
  /// A check mark (success / confirm).
  check,

  /// A cross (dismiss / reject).
  cross,
}

/// A full-width pill button (ports `cs-core.jsx`'s `WideButton`).
///
/// Height 64, fully rounded, with an upper-cased tracked label. The button is
/// disabled — rendered in the panel/faint palette and ignoring taps — whenever
/// [onPressed] is null. Pressing briefly scales it to 0.98 (an instant,
/// non-animated transform, per the project's controller-only motion rule).
class WideButton extends StatefulWidget {
  /// Creates a pill button labelled [label].
  const WideButton({
    required this.label,
    this.onPressed,
    this.variant = WideButtonVariant.solid,
    this.icon,
    super.key,
  });

  /// Button text; rendered upper-cased.
  final String label;

  /// Tap handler; when null the button is disabled.
  final VoidCallback? onPressed;

  /// Fill style — solid (default) or hollow.
  final WideButtonVariant variant;

  /// Optional leading glyph.
  final WideButtonIcon? icon;

  @override
  State<WideButton> createState() => _WideButtonState();
}

class _WideButtonState extends State<WideButton> {
  bool _pressed = false;

  void _setPressed({required bool value}) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final hollow = widget.variant == WideButtonVariant.hollow;

    final background = disabled
        ? CsTokens.panel
        : hollow
        ? CsTokens.bg
        : CsTokens.fg;
    final foreground = disabled
        ? CsTokens.faint
        : hollow
        ? CsTokens.fg
        : CsTokens.bg;
    final border = hollow && !disabled
        ? Border.all(color: CsTokens.fg, width: 1.6)
        : null;

    final pill = Transform.scale(
      scale: _pressed ? 0.98 : 1,
      child: Container(
        height: 64,
        width: double.infinity,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: border,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              _icon(widget.icon!, foreground),
              const SizedBox(width: 10),
            ],
            Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontFamily: CsType.family,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                letterSpacing: 13.5 * 0.22,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );

    if (disabled) return pill;

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (_) => _setPressed(value: true),
      onTapUp: (_) => _setPressed(value: false),
      onTapCancel: () => _setPressed(value: false),
      behavior: HitTestBehavior.opaque,
      child: pill,
    );
  }

  Widget _icon(WideButtonIcon icon, Color color) {
    switch (icon) {
      case WideButtonIcon.check:
        return Check(color: color);
      case WideButtonIcon.cross:
        return Cross(color: color);
    }
  }
}
