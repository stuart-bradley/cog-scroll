import 'dart:math';

import 'package:cogscroll/features/games/corsi/domain/corsi_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('corsiGridSize', () {
    test('is 4×4 up to span 6, then grows to 5×5', () {
      for (var span = 0; span <= 6; span++) {
        expect(corsiGridSize(span), 4, reason: 'span $span');
      }
      expect(corsiGridSize(7), 5);
      expect(corsiGridSize(9), 5);
    });
  });

  group('buildCorsiSequence', () {
    test('has the requested length and distinct, in-range cells', () {
      final seq = buildCorsiSequence(4, 5, Random(1));
      expect(seq, hasLength(5));
      expect(seq.toSet(), hasLength(5)); // all distinct
      expect(seq.every((c) => c >= 0 && c < 16), isTrue);
    });

    test('draws from the larger grid when it has grown', () {
      final seq = buildCorsiSequence(5, 7, Random(2));
      expect(seq, hasLength(7));
      expect(seq.toSet(), hasLength(7));
      expect(seq.every((c) => c >= 0 && c < 25), isTrue);
    });

    test('is deterministic for a given seed', () {
      expect(
        buildCorsiSequence(4, 5, Random(7)),
        buildCorsiSequence(4, 5, Random(7)),
      );
    });
  });
}
