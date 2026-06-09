import 'package:cogscroll/core/scoring/metrics.dart';
import 'package:cogscroll/core/scoring/normalize.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalize', () {
    test('nback maps each breakpoint vertex (eff = acc at n=2)', () {
      expect(normalize('nback', (acc: 40, n: 2)), 15);
      expect(normalize('nback', (acc: 60, n: 2)), 35);
      expect(normalize('nback', (acc: 75, n: 2)), 58);
      expect(normalize('nback', (acc: 85, n: 2)), 78);
      expect(normalize('nback', (acc: 100, n: 2)), 100);
    });

    test('nback interpolates and lifts by level', () {
      expect(normalize('nback', (acc: 50, n: 2)), 25);
      // Level lift: acc 75 at n 4 → eff 105 → clamped to 100, vs 58 at n 2.
      expect(normalize('nback', (acc: 75, n: 4)), 100);
      expect(normalize('nback', (acc: 70, n: 3)), 78);
      expect(normalize('nback', (acc: 0, n: 2)), 15); // below first → clamp
    });

    test('flanker-acc: vertices at level 1, interpolation, clamp', () {
      expect(normalize('flanker-acc', (acc: 60, level: 1)), 10);
      expect(normalize('flanker-acc', (acc: 85, level: 1)), 35);
      expect(normalize('flanker-acc', (acc: 90, level: 1)), 58);
      expect(normalize('flanker-acc', (acc: 95, level: 1)), 80);
      expect(normalize('flanker-acc', (acc: 100, level: 1)), 100);
      // 92.5 → midway between [90,58] and [95,80] → 69.
      expect(normalize('flanker-acc', (acc: 92, level: 1)), 67);
      expect(normalize('flanker-acc', (acc: 50, level: 1)), 10); // clamp
    });

    test('gng-acc: vertices at level 1', () {
      expect(normalize('gng-acc', (acc: 60, level: 1)), 10);
      expect(normalize('gng-acc', (acc: 85, level: 1)), 38);
      expect(normalize('gng-acc', (acc: 92, level: 1)), 62);
      expect(normalize('gng-acc', (acc: 97, level: 1)), 84);
      expect(normalize('gng-acc', (acc: 100, level: 1)), 100);
    });

    test('switch-acc: vertices at level 1', () {
      expect(normalize('switch-acc', (acc: 50, level: 1)), 12);
      expect(normalize('switch-acc', (acc: 70, level: 1)), 40);
      expect(normalize('switch-acc', (acc: 82, level: 1)), 60);
      expect(normalize('switch-acc', (acc: 90, level: 1)), 78);
      expect(normalize('switch-acc', (acc: 100, level: 1)), 100);
    });

    test(
      'leveled accuracy is monotonic in level (eff = acc + (level-1)*10)',
      () {
        for (final key in ['flanker-acc', 'gng-acc', 'switch-acc']) {
          var prev = -1;
          for (var level = 1; level <= 5; level++) {
            final score = normalize(key, (acc: 80, level: level));
            expect(score, greaterThanOrEqualTo(prev), reason: '$key L$level');
            prev = score;
          }
        }
        // acc 80 at level 3 (eff 100) tops the flanker table.
        expect(normalize('flanker-acc', (acc: 80, level: 3)), 100);
      },
    );

    test(
      'stroop: interference cost (lower-is-better) at level 1, with clamps',
      () {
        expect(normalize('stroop', (interferenceMs: 40, level: 1)), 100);
        expect(normalize('stroop', (interferenceMs: 80, level: 1)), 82);
        expect(normalize('stroop', (interferenceMs: 150, level: 1)), 55);
        expect(normalize('stroop', (interferenceMs: 200, level: 1)), 30);
        expect(normalize('stroop', (interferenceMs: 300, level: 1)), 8);
        // 60 → midway between [40,100] and [80,82] → 91.
        expect(normalize('stroop', (interferenceMs: 60, level: 1)), 91);
        expect(
          normalize('stroop', (interferenceMs: 20, level: 1)),
          100,
        ); // clamp
        expect(
          normalize('stroop', (interferenceMs: 400, level: 1)),
          8,
        ); // clamp
      },
    );

    test('stroop credits higher levels (same interference scores higher)', () {
      final l1 = normalize('stroop', (interferenceMs: 150, level: 1));
      final l3 = normalize('stroop', (interferenceMs: 150, level: 3));
      expect(l3, greaterThan(l1));
    });

    test('corsi-span: every vertex, interpolation, and clamps', () {
      expect(normalize('corsi-span', 2), 10);
      expect(normalize('corsi-span', 5), 55);
      expect(normalize('corsi-span', 9), 100);
      expect(normalize('corsi-span', 4), 40);
      expect(normalize('corsi-span', 1), 10); // below first → clamp
      expect(normalize('corsi-span', 11), 100); // above last → clamp
    });

    test('digit-span: forward and backward use their own tables', () {
      expect(
        normalize('digit-span', (span: 3, mode: DigitSpanMode.forward)),
        15,
      );
      expect(
        normalize('digit-span', (span: 8, mode: DigitSpanMode.forward)),
        82,
      );
      expect(
        normalize('digit-span', (span: 10, mode: DigitSpanMode.forward)),
        100,
      );
      expect(
        normalize('digit-span', (span: 2, mode: DigitSpanMode.backward)),
        15,
      );
      expect(
        normalize('digit-span', (span: 5, mode: DigitSpanMode.backward)),
        68,
      );
      expect(
        normalize('digit-span', (span: 8, mode: DigitSpanMode.backward)),
        100,
      );
      // Same span scores higher backward (backward is harder).
      final fwd6 = normalize('digit-span', (
        span: 6,
        mode: DigitSpanMode.forward,
      ));
      final bwd6 = normalize(
        'digit-span',
        (span: 6, mode: DigitSpanMode.backward),
      );
      expect(bwd6, greaterThan(fwd6));
    });

    test('rt-avg: lower-is-better, every vertex, interpolation, clamps', () {
      expect(normalize('rt-avg', 180), 100);
      expect(normalize('rt-avg', 260), 62);
      expect(normalize('rt-avg', 450), 8);
      expect(normalize('rt-avg', 200), 91);
      expect(normalize('rt-avg', 100), 100); // faster than table → clamp high
      expect(normalize('rt-avg', 500), 8); // slower than table → clamp low
    });

    test('trail-time: seconds-per-target, mode A and B curves', () {
      TrailRaw a(double spt) =>
          (seconds: spt * 10, count: 10, mode: TrailMode.a);
      TrailRaw b(double spt) =>
          (seconds: spt * 10, count: 10, mode: TrailMode.b);
      expect(normalize('trail-time', a(1)), 100);
      expect(normalize('trail-time', a(2.5)), 58);
      expect(normalize('trail-time', a(7.5)), 5);
      expect(normalize('trail-time', a(0.5)), 100); // faster than table → clamp
      expect(normalize('trail-time', b(1.8)), 100);
      expect(normalize('trail-time', b(4.5)), 58);
      expect(normalize('trail-time', b(13.5)), 5);
      // Count cancels: same s/target → same score regardless of target count.
      expect(
        normalize('trail-time', (seconds: 50.0, count: 20, mode: TrailMode.a)),
        normalize('trail-time', (seconds: 25.0, count: 10, mode: TrailMode.a)),
      );
    });

    test('unknown key clamps-and-rounds the raw value', () {
      expect(normalize('mystery', 73.2), 73);
      expect(normalize('mystery', 140), 100);
      expect(normalize('mystery', -5), 0);
    });
  });
}
