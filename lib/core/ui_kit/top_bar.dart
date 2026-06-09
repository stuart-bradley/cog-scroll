import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:flutter/widgets.dart';

/// The slim header shown above games and screens (ports `cs-core.jsx`'s
/// `TopBar`).
///
/// Lays out an optional back chevron, an optional upper-cased [title], and an
/// optional [trailing] slot pinned to the right. The back affordance is only
/// rendered when [onBack] is provided, and uses a 44px hit area.
class TopBar extends StatelessWidget {
  /// Creates a top bar with an optional [title], back button and [trailing].
  const TopBar({this.title, this.onBack, this.trailing, super.key});

  /// Centre-left label; omitted when null.
  final String? title;

  /// Back-button handler; the chevron is hidden when null.
  final VoidCallback? onBack;

  /// Optional widget pinned to the right edge.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final onBack = this.onBack;
    final title = this.title;
    final trailing = this.trailing;
    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onBack != null) ...[
                _BackButton(onTap: onBack),
                const SizedBox(width: 8),
              ],
              if (title != null) Label(title),
            ],
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A back chevron wrapped in a 44px square hit target.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox(
        width: 44,
        height: 44,
        child: Align(
          alignment: Alignment.centerLeft,
          child: CustomPaint(
            size: Size.square(20),
            painter: _BackChevronPainter(),
          ),
        ),
      ),
    );
  }
}

class _BackChevronPainter extends CustomPainter {
  const _BackChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Path in a 0..20 box: M12 4 l-6 6 6 6 (a left-pointing chevron).
    canvas
      ..save()
      ..scale(size.width / 20);
    final paint = Paint()
      ..color = CsTokens.fg
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    final path = Path()
      ..moveTo(12, 4)
      ..lineTo(6, 10)
      ..lineTo(12, 16);
    canvas
      ..drawPath(path, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_BackChevronPainter oldDelegate) => false;
}
