import 'dart:math';

import 'package:cogscroll/features/games/gonogo/domain/gonogo_trial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('goNoGoParamsForLevel', () {
    test('Go ratio falls 80→70→60 across the levels', () {
      expect(goNoGoParamsForLevel(1).goRate, 0.8);
      expect(goNoGoParamsForLevel(2).goRate, 0.8);
      expect(goNoGoParamsForLevel(3).goRate, 0.7);
      expect(goNoGoParamsForLevel(4).goRate, 0.6);
      expect(goNoGoParamsForLevel(5).goRate, 0.6);
    });

    test('ISI tightens 1000→400 across the levels', () {
      expect(
        [for (var l = 1; l <= 5; l++) goNoGoParamsForLevel(l).isiMs],
        [1000, 700, 600, 500, 400],
      );
    });

    test('No-Go is the square until L5, then the more circle-like hexagon', () {
      for (var l = 1; l <= 4; l++) {
        expect(goNoGoParamsForLevel(l).noGoShape, gngNoGoSquare, reason: 'L$l');
      }
      expect(goNoGoParamsForLevel(5).noGoShape, gngNoGoHexagon);
    });

    test('clamps out-of-range levels', () {
      expect(goNoGoParamsForLevel(0).goRate, 0.8); // → L1
      expect(goNoGoParamsForLevel(99).isiMs, 400); // → L5
    });
  });

  group('generateGngTrial', () {
    test('a Go trial is the circle; a No-Go is the level No-Go shape', () {
      final params = goNoGoParamsForLevel(5);
      // Sample many trials; every Go is the circle, every No-Go the hexagon.
      final random = Random(3);
      for (var i = 0; i < 200; i++) {
        final t = generateGngTrial(params, random);
        if (t.isGo) {
          expect(t.shape, gngGoShape);
        } else {
          expect(t.shape, gngNoGoHexagon);
        }
      }
    });

    test('honours the Go ratio roughly over many trials', () {
      final params = goNoGoParamsForLevel(1); // 80% Go
      final random = Random(11);
      final gos = [
        for (var i = 0; i < 1000; i++) generateGngTrial(params, random),
      ].where((t) => t.isGo).length;
      expect(gos, greaterThan(700));
      expect(gos, lessThan(900));
    });
  });
}
