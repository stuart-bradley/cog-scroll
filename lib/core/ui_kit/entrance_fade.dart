import 'package:flutter/widgets.dart';

/// Fades and lifts its [child] in once on first build (opacity 0→1,
/// translateY 6→0), matching the prototype's `csFade` entrance.
///
/// Self-contained: owns and disposes its own [AnimationController] and plays
/// it forward on mount (no implicit animation), so callers stay stateless.
class EntranceFade extends StatefulWidget {
  /// Wraps [child] with a fade-and-rise entrance lasting [duration].
  const EntranceFade({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    super.key,
  });

  /// The content to reveal.
  final Widget child;

  /// How long the entrance takes.
  final Duration duration;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, child) {
        return Opacity(
          opacity: _curved.value,
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - _curved.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
