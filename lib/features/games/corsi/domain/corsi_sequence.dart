import 'dart:math';

/// The grid side length for a sequence of [span] cells: 4×4 normally, growing
/// to 5×5 once the span exceeds 6 (`SPEC.md` §7.1) so a longer sequence has
/// room to spread out.
int corsiGridSize(int span) => span > 6 ? 5 : 4;

/// Builds a [length]-cell sequence of distinct cell indices on a
/// `gridN`×`gridN` grid (cells numbered 0…gridN²−1, row-major). [random] is
/// injected for determinism in tests. Ports `docs/design/cs-memory.jsx`.
List<int> buildCorsiSequence(int gridN, int length, Random random) {
  final cells = [for (var i = 0; i < gridN * gridN; i++) i];
  final seq = <int>[];
  for (var i = 0; i < length && cells.isNotEmpty; i++) {
    seq.add(cells.removeAt(random.nextInt(cells.length)));
  }
  return seq;
}
