import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/intro.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_state.dart';
import 'package:flutter/widgets.dart';

/// The Digit Span intro: a three-digit legend, the (mode-specific) rule, and a
/// Begin button.
class DigitSpanIntro extends StatelessWidget {
  /// Creates the intro for [mode].
  const DigitSpanIntro({
    required this.mode,
    required this.onStart,
    super.key,
  });

  /// Forward (same order) or backward (reverse order) recall.
  final DigitSpanMode mode;

  /// Begin handler.
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final backward = mode == DigitSpanMode.backward;
    return Intro(
      text: backward
          ? 'Watch the digits, then tap them back in reverse order.'
          : 'Watch the digits, then tap them back in the same order.',
      startLabel: 'Begin',
      footnote: backward ? 'Backward order' : 'Forward order',
      onStart: onStart,
      legend: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                '${const [4, 1, 9][i]}',
                style: TextStyle(
                  fontFamily: CsType.family,
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                  color: i == 1 ? CsTokens.fg : CsTokens.sub,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
