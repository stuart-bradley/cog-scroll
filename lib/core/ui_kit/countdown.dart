import 'dart:async';

import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/widgets.dart';

/// A linear depleting line for response-window games (ports `cs-core.jsx`'s
/// `Countdown`).
///
/// A 210×3 track whose ink fill shrinks from full to empty over [ms]
/// milliseconds (left-anchored, linear). The countdown restarts from full
/// whenever [trialKey] changes — driven via `didUpdateWidget` rather than a
/// changing widget key, so the [AnimationController] survives across trials.
class Countdown extends StatefulWidget {
  /// Creates a countdown lasting [ms] milliseconds, restarting when [trialKey]
  /// changes.
  const Countdown({required this.ms, required this.trialKey, super.key});

  /// Duration of one depletion, in milliseconds.
  final int ms;

  /// Identity of the current trial; changing it restarts the depletion.
  final Object trialKey;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.ms),
  )..forward();

  @override
  void didUpdateWidget(Countdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ms != oldWidget.ms) {
      _controller.duration = Duration(milliseconds: widget.ms);
    }
    if (widget.trialKey != oldWidget.trialKey || widget.ms != oldWidget.ms) {
      unawaited(_controller.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 210,
        height: 3,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (1 - _controller.value).clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: const ColoredBox(color: CsTokens.fg),
        ),
      ),
    );
  }
}
