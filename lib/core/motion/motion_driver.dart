import 'dart:async';

import 'package:flutter/widgets.dart';

/// Builds a motion frame from the driving [animation] and the wrapped [child].
///
/// Implementations MUST include [child] in their returned tree — that is what
/// structurally guarantees the stimulus stays visible for the whole motion.
typedef MotionBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Widget child,
    );

/// The shared lifecycle behind every CogScroll feedback motion.
///
/// Owns a single [AnimationController] (created eagerly in `initState`, never
/// lazily — a lazy controller would be built during `dispose`), plays it on
/// mount when [playOnMount], replays it whenever [trigger] changes, and fires
/// [onComplete] each time it settles. The [builder] renders each frame around
/// the always-present [child].
class MotionDriver extends StatefulWidget {
  /// Drives [builder] over [duration], wrapping [child].
  const MotionDriver({
    required this.duration,
    required this.builder,
    required this.child,
    this.trigger,
    this.playOnMount = false,
    this.onComplete,
    super.key,
  });

  /// Length of one play.
  final Duration duration;

  /// Renders a single frame from the animation and child.
  final MotionBuilder builder;

  /// The stimulus; always present in the tree across the motion.
  final Widget child;

  /// Changing this value replays the motion (e.g. on each correct answer).
  final Object? trigger;

  /// Play immediately when first built (entrance motions).
  final bool playOnMount;

  /// Called once each time a play reaches its end.
  final VoidCallback? onComplete;

  @override
  State<MotionDriver> createState() => _MotionDriverState();
}

class _MotionDriverState extends State<MotionDriver>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_onStatus);
    if (widget.playOnMount) {
      unawaited(_controller.forward(from: 0));
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onComplete?.call();
    }
  }

  @override
  void didUpdateWidget(MotionDriver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.trigger != oldWidget.trigger) {
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
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => widget.builder(context, _controller, child!),
    );
  }
}
