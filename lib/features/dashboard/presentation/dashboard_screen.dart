import 'dart:math' as math;

import 'package:cogscroll/core/analytics/analytics_providers.dart';
import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/radar.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/dashboard/presentation/widgets/sparkline.dart';
import 'package:cogscroll/features/dashboard/presentation/widgets/trend_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Progress dashboard: a six-spoke radar with a dashed baseline ghost over
/// a per-domain list (sparkline, trend, 0–100 score). Personal trajectory only
/// (DESIGN §7.2; ports `cs-dashboard.jsx`). Reached via Settings → Progress.
class DashboardScreen extends ConsumerWidget {
  /// Creates the dashboard screen.
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(domainScoresProvider);
    final baselines = ref.watch(domainBaselinesProvider).value;

    return Scaffold(
      backgroundColor: CsTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            TopBar(title: 'Progress', onBack: () => context.pop()),
            Expanded(
              child: scores.when(
                data: (data) =>
                    _DashboardBody(scores: data, baselines: baselines),
                loading: () => const SizedBox.shrink(),
                error: (_, _) =>
                    const Center(child: Label('COULD NOT LOAD PROGRESS')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.scores, required this.baselines});

  final Map<String, int?> scores;
  final Map<String, int?>? baselines;

  @override
  Widget build(BuildContext context) {
    final measured = scores.values.where((v) => v != null).length;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
            child: Column(
              children: [
                Radar(scores: scores, ghost: baselines, size: 250),
                const SizedBox(height: 8),
                const _Legend(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final domain in Domains.all)
            _DomainRow(domain: domain, score: scores[domain]),
          _Footer(measured: measured),
        ],
      ),
    );
  }
}

/// "Now" (solid) / "Baseline" (dashed) key beneath the radar.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(label: 'Now', dashed: false),
        SizedBox(width: 18),
        _LegendItem(label: 'Baseline', dashed: true),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.dashed});

  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final color = dashed ? CsTokens.faint : CsTokens.fg;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(16, 2),
          painter: _LegendLinePainter(dashed: dashed, color: color),
        ),
        const SizedBox(width: 7),
        Label(label, size: 9.5, color: dashed ? CsTokens.faint : CsTokens.sub),
      ],
    );
  }
}

class _LegendLinePainter extends CustomPainter {
  const _LegendLinePainter({required this.dashed, required this.color});

  final bool dashed;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..isAntiAlias = true;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    const on = 3.0;
    const off = 2.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + on, size.width), y),
        paint,
      );
      x += on + off;
    }
  }

  @override
  bool shouldRepaint(_LegendLinePainter old) =>
      old.dashed != dashed || old.color != color;
}

/// One domain's row: name + trend mark, a sparkline, and the 0–100 score.
class _DomainRow extends ConsumerWidget {
  const _DomainRow({required this.domain, required this.score});

  final String domain;
  final int? score;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measured = score != null;
    final trend =
        ref.watch(domainTrendProvider(domain)).value ??
        (state: TrendState.none, delta: 0, n: 0);
    final history =
        ref.watch(domainHistoryProvider(domain)).value ?? const <int>[];

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CsTokens.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  domain,
                  style: TextStyle(
                    fontFamily: CsType.family,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 15 * -0.01,
                    color: measured ? CsTokens.fg : CsTokens.sub,
                  ),
                ),
                const SizedBox(height: 9),
                TrendMark(trend: trend),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Sparkline(data: history),
          const SizedBox(width: 14),
          SizedBox(
            width: 36,
            child: Text(
              measured ? '$score' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: CsType.family,
                fontWeight: FontWeight.w600,
                fontSize: 19,
                letterSpacing: 19 * -0.02,
                color: measured ? CsTokens.fg : CsTokens.faint,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Footer caption: how many of the six domains are measured, or the
/// all-measured prompt.
class _Footer extends StatelessWidget {
  const _Footer({required this.measured});

  final int measured;

  @override
  Widget build(BuildContext context) {
    final text = measured < 6
        ? '$measured of 6 domains measured · '
              'play the rest to complete your map'
        : 'Scores update as you play · weakest areas get prioritised';
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: CsTokens.line)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: CsType.family,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
              letterSpacing: 10.5 * 0.18,
              height: 1.6,
              color: CsTokens.faint,
            ),
          ),
        ),
      ),
    );
  }
}
