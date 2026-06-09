import 'package:cogscroll/core/motion/pulse.dart';
import 'package:cogscroll/core/motion/shake.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/icons.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/features/games/corsi/domain/corsi_state.dart';
import 'package:flutter/widgets.dart';

const double _gridExtent = 300;
const double _gridGap = 10;

/// The Corsi play surface: a square grid that flashes the sequence then accepts
/// taps, with pulse / shake feedback that keeps the grid visible, and a stage
/// hint.
class CorsiPlaying extends StatelessWidget {
  /// Creates the play UI from the engine [state].
  const CorsiPlaying({required this.state, required this.onTapCell, super.key});

  /// Current engine snapshot.
  final CorsiState state;

  /// Cell-tap handler.
  final void Function(int cell) onTapCell;

  @override
  Widget build(BuildContext context) {
    final recall = state.stage == CorsiStage.recall;
    return Column(
      children: [
        Expanded(
          child: Center(child: _grid(recall: recall)),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: Label(
            recall ? 'Repeat the sequence' : 'Watch',
            color: CsTokens.faint,
          ),
        ),
      ],
    );
  }

  Widget _grid({required bool recall}) {
    final n = state.gridN;
    final cellSize = (_gridExtent - _gridGap * (n - 1)) / n;
    final grid = SizedBox(
      width: _gridExtent,
      child: Wrap(
        spacing: _gridGap,
        runSpacing: _gridGap,
        children: [
          for (var c = 0; c < n * n; c++)
            _Cell(
              key: ValueKey('corsi-cell-$c'),
              size: cellSize,
              filled: state.lit == c || (recall && state.taps.contains(c)),
              bad: state.bad == c,
              onTap: recall ? () => onTapCell(c) : null,
            ),
        ],
      ),
    );
    switch (state.fb) {
      case CorsiFeedback.hit:
        return Pulse(
          trigger: state.trial,
          size: _gridExtent * 0.92,
          child: grid,
        );
      case CorsiFeedback.wrong:
        return Shake(trigger: state.trial, playOnMount: true, child: grid);
      case null:
        return grid;
    }
  }
}

/// One grid cell — filled ink when lit/tapped, a panel square otherwise, with a
/// cross when it is the wrong cell.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.size,
    required this.filled,
    required this.bad,
    this.onTap,
    super.key,
  });

  final double size;
  final bool filled;
  final bool bad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: filled ? CsTokens.fg : CsTokens.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: bad ? CsTokens.fg : CsTokens.line,
            width: bad ? 2 : 1.5,
          ),
        ),
        child: bad ? const Center(child: Cross(size: 20)) : null,
      ),
    );
  }
}
