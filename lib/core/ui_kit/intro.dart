import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/entrance_fade.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/wide_button.dart';
import 'package:flutter/widgets.dart';

/// A calm game-start screen (ports `cs-core.jsx`'s `Intro`).
///
/// Centres an optional [legend] (typically a stimulus demo), the instruction
/// [text], and an optional [footnote] label, with a start button pinned to the
/// bottom. The content fades and rises in on first build via [EntranceFade],
/// matching the prototype's `csFade` entrance.
class Intro extends StatelessWidget {
  /// Creates an intro screen with instruction [text] and a [startLabel] button.
  const Intro({
    required this.text,
    required this.startLabel,
    this.legend,
    this.footnote,
    this.onStart,
    super.key,
  });

  /// The main instruction text.
  final String text;

  /// Label for the start button.
  final String startLabel;

  /// Optional visual shown above the text (e.g. a demo stimulus).
  final Widget? legend;

  /// Optional dimmed caption shown below the text.
  final String? footnote;

  /// Start handler; the button is disabled when null.
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EntranceFade(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (legend != null) ...[
                    legend!,
                    const SizedBox(height: 30),
                  ],
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: CsType.family,
                      fontWeight: FontWeight.w500,
                      fontSize: 21,
                      height: 1.45,
                      color: CsTokens.fg,
                    ),
                  ),
                  if (footnote != null) ...[
                    const SizedBox(height: 30),
                    Label(footnote!),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 46),
          child: WideButton(label: startLabel, onPressed: onStart),
        ),
      ],
    );
  }
}
