import 'dart:math';

import 'package:cogscroll/features/games/flanker/domain/flanker_state.dart';
import 'package:cogscroll/features/games/flanker/domain/flanker_trial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('flankerParamsForLevel', () {
    test('L1 is congruent with one flanker and the lenient window', () {
      final p = flankerParamsForLevel(1);
      expect(p.congruent, isTrue);
      expect(p.flankersPerSide, 1);
      expect(p.windowMs, flankerBaseWindowMs);
      expect(p.fullSizeFlankers, isFalse);
    });

    test('L2 turns incongruent, still one flanker', () {
      final p = flankerParamsForLevel(2);
      expect(p.congruent, isFalse);
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
      expect(flankerParamsForLevel(0).congruent, isTrue); // → L1
      expect(flankerParamsForLevel(99).windowMs, 300); // → L5
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
