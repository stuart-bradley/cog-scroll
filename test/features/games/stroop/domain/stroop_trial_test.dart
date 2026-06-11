import 'dart:math';

import 'package:cogscroll/features/games/stroop/domain/stroop_trial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stroopParamsForLevel', () {
    test('options grow and the window tightens with the level', () {
      expect(stroopParamsForLevel(1).optionCount, 3);
      expect(stroopParamsForLevel(3).optionCount, 4);
      expect(stroopParamsForLevel(5).optionCount, 5);
      expect(stroopParamsForLevel(1).windowMs, 3000);
      expect(stroopParamsForLevel(5).windowMs, 1600);
      expect(
        stroopParamsForLevel(5).windowMs,
        lessThan(stroopParamsForLevel(1).windowMs),
      );
    });

    test('confusable shapes only enter at L4+', () {
      expect(stroopParamsForLevel(1).confusable, isFalse);
      expect(stroopParamsForLevel(3).confusable, isFalse);
      expect(stroopParamsForLevel(4).confusable, isTrue);
      expect(stroopParamsForLevel(5).confusable, isTrue);
    });

    test('the level is clamped to 1–5', () {
      expect(stroopParamsForLevel(0).optionCount, 3);
      expect(stroopParamsForLevel(9).optionCount, 5);
    });
  });

  group('generateStroopStim', () {
    test('the drawn shape is always among the options, count per level', () {
      for (var level = 1; level <= 5; level++) {
        final want = stroopParamsForLevel(level).optionCount;
        for (var seed = 0; seed < 40; seed++) {
          final stim = generateStroopStim(level, Random(seed));
          expect(stim.options, hasLength(want), reason: 'L$level seed$seed');
          expect(stim.options, contains(stim.shape));
          expect(stim.options.toSet(), hasLength(want)); // distinct
        }
      }
    });

    test('congruent ⇒ word equals shape; incongruent ⇒ differs', () {
      for (var seed = 0; seed < 60; seed++) {
        final stim = generateStroopStim(1, Random(seed));
        if (stim.congruent) {
          expect(stim.word, stim.shape);
        } else {
          expect(stim.word, isNot(stim.shape));
        }
      }
    });

    test('at confusable levels an incongruent word is a neighbour', () {
      var sawIncongruent = false;
      for (var seed = 0; seed < 80; seed++) {
        final stim = generateStroopStim(5, Random(seed));
        final neighbours = stroopConfusable[stim.shape]!;
        if (!stim.congruent && neighbours.isNotEmpty) {
          sawIncongruent = true;
          expect(neighbours, contains(stim.word));
        }
      }
      expect(sawIncongruent, isTrue, reason: 'expected incongruent trials');
    });
  });
}
