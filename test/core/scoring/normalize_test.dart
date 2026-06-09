import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalize', () {
    test('nback maps each breakpoint vertex (eff = acc)', () {
      // n == 2 → eff == acc, so these hit the table's raw x values directly.
      expect(normalize('nback', (acc: 40, n: 2)), 15);
      expect(normalize('nback', (acc: 60, n: 2)), 35);
      expect(normalize('nback', (acc: 75, n: 2)), 58);
      expect(normalize('nback', (acc: 85, n: 2)), 78);
      expect(normalize('nback', (acc: 100, n: 2)), 100);
    });

    test('nback interpolates and lifts by level', () {
      // eff = 50 → midway between [40,15] and [60,35] → 25.
      expect(normalize('nback', (acc: 50, n: 2)), 25);
      // Level lift: acc 75 at n 4 → eff 105 → clamped to 100, vs 58 at n 2.
      expect(normalize('nback', (acc: 75, n: 4)), 100);
      // acc 70 at n 3 → eff 85 → 78.
      expect(normalize('nback', (acc: 70, n: 3)), 78);
    });

    test('digit-span vertices, interpolation, and clamping', () {
      expect(normalize('digit-span', 3), 15);
      expect(normalize('digit-span', 6), 55);
      expect(normalize('digit-span', 10), 100);
      // 5 → midway between [4,30] and [6,55] → 42.5 → 43 (half-up).
      expect(normalize('digit-span', 5), 43);
      expect(normalize('digit-span', 2), 15); // below first → clamp
      expect(normalize('digit-span', 12), 100); // above last → clamp
    });

    test('corsi-span vertices and interpolation', () {
      expect(normalize('corsi-span', 2), 10);
      expect(normalize('corsi-span', 9), 100);
      // 4 → midway between [3,25] and [5,55] → 40.
      expect(normalize('corsi-span', 4), 40);
    });

    test('rt-avg is lower-is-better (rising ms → falling score)', () {
      expect(normalize('rt-avg', 180), 100);
      expect(normalize('rt-avg', 450), 8);
      // 200 → midway between [180,100] and [220,82] → 91.
      expect(normalize('rt-avg', 200), 91);
      expect(normalize('rt-avg', 100), 100); // faster than table → clamp high
      expect(normalize('rt-avg', 500), 8); // slower than table → clamp low
    });

    test('trail-time is lower-is-better', () {
      expect(normalize('trail-time', 12), 100);
      expect(normalize('trail-time', 90), 5);
      // 16 → midway between [12,100] and [20,82] → 91.
      expect(normalize('trail-time', 16), 91);
    });

    test('flanker-acc vertices and interpolation', () {
      expect(normalize('flanker-acc', 60), 10);
      expect(normalize('flanker-acc', 100), 100);
      // 92.5 → midway between [90,58] and [95,80] → 69.
      expect(normalize('flanker-acc', 92.5), 69);
    });

    test('gng-acc vertices', () {
      expect(normalize('gng-acc', 60), 10);
      expect(normalize('gng-acc', 92), 62);
      expect(normalize('gng-acc', 100), 100);
    });

    test('stroop-acc and switch-acc share the same table', () {
      for (final key in ['stroop-acc', 'switch-acc']) {
        expect(normalize(key, 50), 12);
        expect(normalize(key, 100), 100);
        // 60 → midway between [50,12] and [70,40] → 26.
        expect(normalize(key, 60), 26);
      }
    });

    test('unknown key clamps-and-rounds the raw value', () {
      expect(normalize('mystery', 73.2), 73);
      expect(normalize('mystery', 140), 100);
      expect(normalize('mystery', -5), 0);
    });
  });
}
