import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/icons.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:flutter/widgets.dart';

/// The unified header drawn over a runner-driven game (baseline / Today
/// session). Ports the prototype's onboarding `Header` (`cs-onboarding.jsx`):
/// an optional Exit (✕), a `<label> · NN / TT` step count, a Skip action, and a
/// per-step progress bar.
///
/// `GameScaffold` renders this in place of the standalone `TopBar` whenever a
/// [RunnerContext] is present, so every runner-capable game gets it for free.
class RunnerHeader extends StatelessWidget {
  /// Creates a header for the given runner [context].
  const RunnerHeader(this.context, {super.key});

  /// The active runner context (step position, label, Skip / Exit callbacks).
  final RunnerContext context;

  String _pad(int x) => x.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext _) {
    final onExit = context.onExit;
    final label = context.headerLabel;
    final count = '${_pad(context.index + 1)} / ${_pad(context.total)}';
    final text = label == null ? count : '$label · $count';

    return Padding(
      padding: const EdgeInsets.only(top: 30, left: 24, right: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onExit != null) ...[
                    _HitTarget(onTap: onExit, child: const Cross(size: 18)),
                    const SizedBox(width: 8),
                  ],
                  Label(text),
                ],
              ),
              _HitTarget(
                onTap: context.onSkip,
                child: const Label('Skip', color: CsTokens.faint),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            key: const Key('runner_progress'),
            children: [
              for (var i = 0; i < context.total; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < context.index
                          ? CsTokens.fg
                          : i == context.index
                          ? CsTokens.sub
                          : CsTokens.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Wraps a small glyph / label in a ~44px tap target (DESIGN tap-target rule).
class _HitTarget extends StatelessWidget {
  const _HitTarget({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 44,
        child: Center(child: child),
      ),
    );
  }
}
