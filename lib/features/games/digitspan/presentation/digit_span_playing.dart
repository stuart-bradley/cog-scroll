import 'package:cogscroll/core/motion/bloom.dart';
import 'package:cogscroll/core/motion/pop.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_state.dart';
import 'package:flutter/widgets.dart';

/// The Digit Span play surface: a big flashing digit during show, then recall
/// slots (with bloom / shake feedback) over a 0–9 keypad. In backward mode a
/// reverse hint reminds the player to tap the digits in reverse.
class DigitSpanPlaying extends StatelessWidget {
  /// Creates the play UI from the engine [state].
  const DigitSpanPlaying({required this.state, required this.onPad, super.key});

  /// Current engine snapshot.
  final DigitSpanState state;

  /// Keypad-tap handler.
  final void Function(int digit) onPad;

  static const _digitStyle = TextStyle(
    fontFamily: CsType.family,
    fontWeight: FontWeight.w600,
    fontSize: 132,
    color: CsTokens.fg,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final recall = state.stage == DigitSpanStage.recall;
    return Column(
      children: [
        Expanded(child: Center(child: recall ? _recall() : _show())),
        if (recall)
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 36),
            child: _Keypad(onPad: onPad),
          )
        else
          const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Label('Remember', color: CsTokens.faint),
          ),
      ],
    );
  }

  Widget _show() {
    final digit = state.digit;
    return SizedBox(
      height: 140,
      child: Center(
        child: digit == null
            ? const SizedBox.shrink()
            : Pop(
                trigger: '$digit-${state.trial}',
                child: Text('$digit', style: _digitStyle),
              ),
      ),
    );
  }

  Widget _recall() {
    final slots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < state.level; i++)
          SizedBox(
            width: 26,
            child: Text(
              i < state.input.length ? '${state.input[i]}' : '·',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: CsType.family,
                fontWeight: FontWeight.w600,
                fontSize: 40,
                color: i < state.input.length ? CsTokens.fg : CsTokens.faint,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
    final feedback = switch (state.fb) {
      DigitSpanFeedback.hit => Bloom(
        trigger: state.trial,
        size: 150,
        child: slots,
      ),
      DigitSpanFeedback.wrong => Shake(
        trigger: state.trial,
        playOnMount: true,
        child: slots,
      ),
      null => slots,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.mode == DigitSpanMode.backward) ...[
          const Label('In reverse', color: CsTokens.faint, size: 10),
          const SizedBox(height: 16),
        ],
        feedback,
      ],
    );
  }
}

/// The 0–9 keypad: fixed-height (64) rows of three, the bottom row blank · 0 ·
/// blank. Fixed row height (rather than an aspect ratio) keeps the keypad a
/// constant size regardless of the surface width.
class _Keypad extends StatelessWidget {
  const _Keypad({required this.onPad});

  final void Function(int digit) onPad;

  static const _rows = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 9],
    [-1, 0, -1],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < _rows.length; r++)
          Padding(
            padding: EdgeInsets.only(top: r == 0 ? 0 : 10),
            child: Row(
              children: [
                for (var c = 0; c < 3; c++) ...[
                  if (c > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _rows[r][c] < 0
                        ? const SizedBox(height: 64)
                        : _Key(
                            key: ValueKey('digit-key-${_rows[r][c]}'),
                            digit: _rows[r][c],
                            onTap: () => onPad(_rows[r][c]),
                          ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.digit, required this.onTap, super.key});

  final int digit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: CsTokens.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CsTokens.line, width: 1.5),
        ),
        child: Center(
          child: Text(
            '$digit',
            style: const TextStyle(
              fontFamily: CsType.family,
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: CsTokens.fg,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
