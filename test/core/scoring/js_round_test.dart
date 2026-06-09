import 'package:cogscroll/core/scoring/js_round.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('jsRound (half-up, matching JS Math.round)', () {
    test('rounds positive halves up', () {
      expect(jsRound(2.5), 3);
      expect(jsRound(0.5), 1);
      expect(jsRound(2.4), 2);
      expect(jsRound(2.6), 3);
    });

    test('rounds negative halves toward positive infinity (JS parity)', () {
      // Dart's num.round() would give -3 here; JS Math.round gives -2.
      expect(jsRound(-2.5), -2);
      expect(jsRound(-0.5), 0);
      expect(jsRound(-2.6), -3);
    });

    test('leaves whole numbers unchanged', () {
      expect(jsRound(3), 3);
      expect(jsRound(-3), -3);
      expect(jsRound(0), 0);
    });
  });
}
