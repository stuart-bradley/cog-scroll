import 'dart:math';

import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_trial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('flankerParamsForLevel', () {
    test('L1 is all-congruent with one flanker and the lenient window', () {
      final p = flankerParamsForLevel(1);
      expect(p.congruentRate, 1.0);
      expect(p.flankersPerSide, 1);
      expect(p.windowMs, flankerBaseWindowMs);
      expect(p.fullSizeFlankers, isFalse);
    });

    test('L2 drops to the incongruent-heavy mix, still one flanker', () {
      final p = flankerParamsForLevel(2);
      expect(p.congruentRate, flankerCongruentRate);
      expect(p.flankersPerSide, 1);
      expect(p.windowMs, flankerBaseWindowMs);
    });

    test('L3 adds a second flanker per side', () {
      expect(flankerParamsForLevel(3).flankersPerSide, 2);
    });

    test('L4 tightens the window to 500 ms', () {
      expect(flankerParamsForLevel(4).windowMs, 500);
      expect(flankerParamsForLevel(4).flankersPerSide, 2);
    });

    test('L5 tightens to 300 ms and grows flankers to target size', () {
      final p = flankerParamsForLevel(5);
      expect(p.windowMs, 300);
      expect(p.fullSizeFlankers, isTrue);
    });

    test('clamps out-of-range levels to 1–5', () {
      expect(flankerParamsForLevel(0).congruentRate, 1.0); // → L1
      expect(flankerParamsForLevel(99).windowMs, 300); // → L5
    });
  });

  group('generateFlankerStim', () {
    test('L1 is always congruent (the easy floor)', () {
      final random = Random(5);
      for (var i = 0; i < 200; i++) {
        expect(generateFlankerStim(1, random).congruent, isTrue);
      }
    });

    test('above L1 it is a probabilistic mix near the 0.4 congruent rate', () {
      final random = Random(5);
      final congruent = [
        for (var i = 0; i < 1000; i++) generateFlankerStim(2, random),
      ].where((s) => s.congruent).length;
      // ~40% congruent — a per-trial mix, neither all-congruent nor all-
      // incongruent (the classic flanker design).
      expect(congruent, greaterThan(300));
      expect(congruent, lessThan(500));
    });

    test('the target direction varies across trials', () {
      final random = Random(5);
      final dirs = {
        for (var i = 0; i < 50; i++) generateFlankerStim(3, random).dir,
      };
      expect(
        dirs,
        containsAll(<FlankerDir>{FlankerDir.left, FlankerDir.right}),
      );
    });
  });

  test('randomFlankerDir yields both directions deterministically', () {
    final dirs = [for (var i = 0; i < 20; i++) randomFlankerDir(Random(7))];
    // Same seed each call → same direction; both values are reachable.
    expect(dirs.toSet().length, 1);
    final mixed = {
      randomFlankerDir(Random(1)),
      randomFlankerDir(Random(2)),
      randomFlankerDir(Random(3)),
      randomFlankerDir(Random(4)),
    };
    expect(mixed, containsAll(<FlankerDir>{FlankerDir.left, FlankerDir.right}));
  });
}
