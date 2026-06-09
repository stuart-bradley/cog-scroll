import 'dart:async';

import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// A round counter with a depleting fill track (ports `cs-core.jsx`'s
/// `Progress`).
///
/// Shows `"08 / 20"` — the current [idx] zero-padded to two digits with the
/// `/ total` portion dimmed — above a 188×2 track whose ink fill spans
/// `idx / total`. The fill width eases over 200ms whenever [idx] changes, via
/// an [AnimationController] (no implicit animation), per the motion rule.
class Progress extends StatefulWidget {
  /// Creates a progress indicator at [idx] of [total].
  const Progress({required this.idx, required this.total, super.key});

  /// Current 1-based position (rendered zero-padded to two digits).
  final int idx;

  /// Total number of rounds.
  final int total;

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress>
    with SingleTickerProviderStateMixin {
  static const double _trackWidth = 188;

  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late Animation<double> _fill;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1,
    );
    // One CurvedAnimation reused for every update: its constructor registers a
    // status listener on the long-lived controller, so recreating it per idx
    // change would leak a listener each round.
    _curve = CurvedAnimation(parent: _controller, curve: Curves.ease);
    _fill = AlwaysStoppedAnimation(_fractionFor(widget));
  }

  double _fractionFor(Progress w) {
    if (w.total <= 0) return 0;
    return (w.idx / w.total).clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(Progress oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _fractionFor(widget);
    final current = _fill.value;
    if (next != current) {
      _fill = Tween<double>(begin: current, end: next).animate(_curve);
      unawaited(_controller.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padded = widget.idx.toString().padLeft(2, '0');
    final dim = CsTokens.sub.withValues(alpha: CsTokens.sub.a * 0.55);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: padded),
              TextSpan(
                text: ' / ${widget.total}',
                style: TextStyle(color: dim),
              ),
            ],
          ),
          style: const TextStyle(
            fontFamily: CsType.family,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 14 * 0.14,
            color: CsTokens.sub,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            width: _trackWidth,
            height: 2,
            child: ColoredBox(
              color: CsTokens.line,
              child: AnimatedBuilder(
                animation: _fill,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _fill.value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: const ColoredBox(color: CsTokens.fg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
