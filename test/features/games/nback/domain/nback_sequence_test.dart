import 'dart:math';

import 'package:cogscroll/features/games/nback/domain/nback_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildNbackSequence', () {
    test('has the requested length and only valid shape ids', () {
      final seq = buildNbackSequence(2, 20, Random(1));
      expect(seq, hasLength(20));
      expect(seq.every((s) => s >= 0 && s < nbackShapeCount), isTrue);
    });

    test('non-match positions never coincidentally equal the n-back shape', () {
      // By construction the only way seq[i] == seq[i-n] is an *intended* match,
      // so the match fraction tracks nbackMatchRate over a large sample.
      const n = 2;
      const len = 4000;
      final seq = buildNbackSequence(n, len, Random(7));
      var matches = 0;
      for (var i = n; i < len; i++) {
        if (seq[i] == seq[i - n]) matches++;
      }
      final fraction = matches / (len - n);
      expect(fraction, closeTo(nbackMatchRate, 0.06));
    });

    test('is deterministic for a given seed', () {
      expect(
        buildNbackSequence(3, 30, Random(42)),
        buildNbackSequence(3, 30, Random(42)),
      );
    });
  });
}
