import 'dart:math';

import 'package:cogscroll/features/games/digitspan/domain/digit_span_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildDigitSequence', () {
    test('has the requested length and only single digits 0–9', () {
      final seq = buildDigitSequence(7, Random(1));
      expect(seq, hasLength(7));
      expect(seq.every((d) => d >= 0 && d <= 9), isTrue);
    });

    test('is deterministic for a given seed', () {
      expect(
        buildDigitSequence(6, Random(3)),
        buildDigitSequence(6, Random(3)),
      );
    });
  });
}
