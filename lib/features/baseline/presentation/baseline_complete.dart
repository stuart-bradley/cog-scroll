import 'package:cogscroll/core/analytics/analytics_providers.dart';
import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/radar.dart';
import 'package:cogscroll/core/ui_kit/wide_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const double _radarSize = 258;

/// The baseline completion screen — "Your starting map" with the freshly-seeded
/// radar revealed (fade + scale), and a Done button. Ports the prototype's
/// `Complete` (`cs-onboarding.jsx`); reads the current scores from analytics.
class BaselineComplete extends ConsumerWidget {
  /// Creates the completion screen; [onDone] continues to Home.
  const BaselineComplete({required this.onDone, super.key});

  /// Tapped via "Done" — leaves the baseline for Home.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(domainScoresProvider);
    return Column(
      children: [
        Expanded(
          child: scores.when(
            data: (data) => _Body(scores: data),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const Center(child: Label('COULD NOT LOAD MAP')),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 46),
          child: WideButton(label: 'Done', onPressed: onDone),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.scores});

  final Map<String, int?> scores;

  @override
  Widget build(BuildContext context) {
    final measured = scores.values.where((v) => v != null).length;
    final caption = measured >= 6
        ? 'All six domains seeded. From here we track only your own '
              'trajectory — never anyone else’s.'
        : '$measured of 6 domains seeded. Play the skipped games any time to '
              'fill in the rest.';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Label('Baseline complete'),
        const SizedBox(height: 6),
        const Text(
          'Your starting map',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: CsType.family,
            fontWeight: FontWeight.w600,
            fontSize: 25,
            letterSpacing: 25 * -0.02,
            color: CsTokens.fg,
          ),
        ),
        const SizedBox(height: 16),
        _Reveal(
          child: Radar(scores: scores, size: _radarSize),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              caption,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: CsType.family,
                fontWeight: FontWeight.w500,
                fontSize: 14.5,
                height: 1.45,
                color: CsTokens.sub,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fades and scales the radar in on first build (opacity 0→1, scale 0.82→1
/// over 0.7s), porting the prototype's `csReveal` keyframe.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: const Cubic(0.2, 0.8, 0.2, 1),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.82 + 0.18 * t, child: child),
      ),
      child: child,
    );
  }
}
