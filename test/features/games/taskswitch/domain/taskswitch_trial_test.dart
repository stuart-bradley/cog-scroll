import 'dart:math';

import 'package:cogscroll/features/games/taskswitch/domain/taskswitch_trial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('switchParamsForLevel', () {
    test('cadence tightens then goes random, window tightens at L4+', () {
      expect(switchParamsForLevel(1).cadence, 4);
      expect(switchParamsForLevel(2).cadence, 2);
      expect(switchParamsForLevel(3).cadence, isNull);
      expect(switchParamsForLevel(4).cadence, isNull);
      expect(switchParamsForLevel(1).windowMs, 2200);
      expect(switchParamsForLevel(4).windowMs, 1600);
      expect(switchParamsForLevel(5).windowMs, 1600);
    });

    test('size enters the rule rotation only at L5', () {
      for (var l = 1; l <= 4; l++) {
        expect(
          switchParamsForLevel(l).rules,
          [SwitchRule.shape, SwitchRule.fill],
          reason: 'L$l',
        );
      }
      expect(switchParamsForLevel(5).rules, [
        SwitchRule.shape,
        SwitchRule.fill,
        SwitchRule.size,
      ]);
    });
  });

  group('switchCorrectChoice', () {
    const circleFilledBig = (shape: 0, filled: true, big: true);
    const squareHollowSmall = (shape: 1, filled: false, big: false);

    test('shape rule maps circle→0, square→1', () {
      expect(switchCorrectChoice(SwitchRule.shape, circleFilledBig), 0);
      expect(switchCorrectChoice(SwitchRule.shape, squareHollowSmall), 1);
    });

    test('fill rule maps filled→0, hollow→1', () {
      expect(switchCorrectChoice(SwitchRule.fill, circleFilledBig), 0);
      expect(switchCorrectChoice(SwitchRule.fill, squareHollowSmall), 1);
    });

    test('size rule maps big→0, small→1', () {
      expect(switchCorrectChoice(SwitchRule.size, circleFilledBig), 0);
      expect(switchCorrectChoice(SwitchRule.size, squareHollowSmall), 1);
    });
  });

  group('switchOptionLabels', () {
    test('relabel per active rule', () {
      expect(switchOptionLabels(SwitchRule.shape), ['Circle', 'Square']);
      expect(switchOptionLabels(SwitchRule.fill), ['Filled', 'Hollow']);
      expect(switchOptionLabels(SwitchRule.size), ['Big', 'Small']);
    });
  });

  group('generateSwitchStim', () {
    test('size stays big below L5 (un-judged dimension fixed)', () {
      for (var seed = 0; seed < 40; seed++) {
        expect(generateSwitchStim(3, Random(seed)).big, isTrue);
      }
    });

    test('size varies at L5 (it can be the rule)', () {
      final sizes = {
        for (var seed = 0; seed < 40; seed++)
          generateSwitchStim(5, Random(seed)).big,
      };
      expect(sizes, containsAll([true, false]));
    });
  });
}
