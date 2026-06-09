import 'dart:math';

/// Builds a [length]-long sequence of single digits (0–9). [random] is injected
/// for determinism in tests. Ports `docs/design/cs-memory.jsx`.
List<int> buildDigitSequence(int length, Random random) => [
  for (var i = 0; i < length; i++) random.nextInt(10),
];
