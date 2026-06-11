import 'dart:math';

import 'package:cogscroll/features/games/trails/domain/trails_state.dart';

/// Virtual board width the targets are laid out on (the prototype's 326×540
/// play surface; the widget scales it to the screen).
const double trailBoardW = 326;

/// Virtual board height. See [trailBoardW].
const double trailBoardH = 540;

/// Target counts for difficulty levels 1–5 (`SPEC.md` §7.1): 8 · 12 · 16 ·
/// 20 (smaller dots) · 25 (small, crowded).
const List<int> trailCounts = [8, 12, 16, 20, 25];

/// The target count for difficulty [level] (clamped to 1–5).
int trailCountForLevel(int level) => trailCounts[level.clamp(1, 5) - 1];

/// The dot radius for difficulty [level]: the prototype's 24 up to L3, then
/// smaller dots at L4–L5 (the §7.1 visual-difficulty lever).
double trailRadiusForLevel(int level) => level.clamp(1, 5) >= 4 ? 19 : 24;

/// Grid columns for [count] targets — more columns as the board crowds, so
/// every cell keeps enough room for a jittered dot.
int trailColsForCount(int count) => count <= 12
    ? 3
    : count <= 20
    ? 4
    : 5;

/// The label of the target at sequence [index]: Mode A counts 1→N; Mode B
/// alternates number/letter (1, A, 2, B, 3, C, …).
String trailLabel(int index, TrailMode mode) {
  if (mode == TrailMode.a) return '${index + 1}';
  return index.isEven
      ? '${index ~/ 2 + 1}'
      : String.fromCharCode(65 + index ~/ 2);
}

/// Lays out [count] labelled targets on the virtual board (ports `genPoints`
/// in `docs/design/cs-flex.jsx`): shuffle the grid cells, then place each
/// target at a jittered point inside its own cell. The `radius + 6` cell
/// padding keeps any two dots at least 12 px apart edge-to-edge.
List<TrailTarget> generateTrailTargets({
  required int count,
  required TrailMode mode,
  required double radius,
  required Random random,
}) {
  final cols = trailColsForCount(count);
  final rows = (count / cols).ceil();
  final cw = trailBoardW / cols;
  final ch = trailBoardH / rows;
  final pad = radius + 6;
  final cells = List<int>.generate(cols * rows, (i) => i)..shuffle(random);
  return [
    for (var i = 0; i < count; i++)
      (
        x: (cells[i] % cols) * cw + pad + random.nextDouble() * (cw - 2 * pad),
        y: (cells[i] ~/ cols) * ch + pad + random.nextDouble() * (ch - 2 * pad),
        label: trailLabel(i, mode),
      ),
  ];
}
