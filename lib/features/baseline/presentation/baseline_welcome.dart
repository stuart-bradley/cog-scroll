import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/entrance_fade.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/shape.dart';
import 'package:cogscroll/core/ui_kit/wide_button.dart';
import 'package:flutter/widgets.dart';

/// The baseline welcome screen — "Find your baseline" with a Begin /
/// Maybe-later choice. Ports the prototype's `Welcome` (`cs-onboarding.jsx`).
class BaselineWelcome extends StatelessWidget {
  /// Creates the welcome screen. [onStart] begins the run; [onExit] bails out.
  const BaselineWelcome({
    required this.onStart,
    required this.onExit,
    super.key,
  });

  /// Tapped via "Begin" — starts the first game.
  final VoidCallback onStart;

  /// Tapped via "Maybe later" — leaves onboarding.
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: EntranceFade(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 6; i++) ...[
                        if (i > 0) const SizedBox(width: 9),
                        Shape(id: i, size: 20, color: CsTokens.sub),
                      ],
                    ],
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Find your baseline',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: CsType.family,
                      fontWeight: FontWeight.w600,
                      fontSize: 28,
                      letterSpacing: 28 * -0.02,
                      height: 1.1,
                      color: CsTokens.fg,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Six short games, one for each cognitive '
                    'domain. About five minutes. This maps where '
                    'you’re starting from, so each day can focus '
                    'where it helps most.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: CsType.family,
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                      height: 1.5,
                      color: CsTokens.sub,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Label(
                    '6 games · ~5 min · skippable',
                    color: CsTokens.faint,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 34),
          child: Column(
            children: [
              WideButton(label: 'Begin', onPressed: onStart),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onExit,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Label('Maybe later'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
