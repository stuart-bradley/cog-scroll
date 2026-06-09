import 'package:cogscroll/features/games/shared/staircase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelStaircase (two-consecutive ±1)', () {
    LevelStaircase make() => LevelStaircase(
      level: 2,
      min: 1,
      max: 4,
      upThreshold: 85,
      downThreshold: 60,
    );

    test('steps up only after two consecutive qualifying rounds', () {
      final s = make();
      expect(s.recordRound(90), 0); // first up round — streak 1
      expect(s.level, 2);
      expect(s.recordRound(90), 1); // second — level up, streak reset
      expect(s.level, 3);
      expect(s.streak, 0);
    });

    test('steps down after two consecutive failing rounds', () {
      final s = make();
      expect(s.recordRound(50), 0);
      expect(s.recordRound(50), -1);
      expect(s.level, 1);
    });

    test('a dead-zone round resets the streak', () {
      final s = make()..recordRound(90); // up, streak 1
      expect(s.recordRound(70), 0); // between thresholds → reset
      expect(s.streak, 0);
      expect(s.recordRound(90), 0); // streak 1 again, no jump
      expect(s.level, 2);
    });

    test('a flip resets rather than crossing zero in one step', () {
      final s = make()..recordRound(90); // streak +1
      expect(s.recordRound(50), 0); // flips to -1, not a down yet
      expect(s.streak, -1);
    });

    test('clamps at max and min', () {
      final up = LevelStaircase(
        level: 4,
        min: 1,
        max: 4,
        upThreshold: 85,
        downThreshold: 60,
      );
      expect(up.recordRound(90), 0);
      expect(up.recordRound(90), 0); // would step up but already at max
      expect(up.level, 4);

      final down =
          LevelStaircase(
              level: 1,
              min: 1,
              max: 4,
              upThreshold: 85,
              downThreshold: 60,
            )
            ..recordRound(50)
            ..recordRound(50);
      expect(down.level, 1);
    });

    test('lowerIsBetter inverts the comparison (time / interference)', () {
      final s =
          LevelStaircase(
              level: 2,
              min: 1,
              max: 5,
              upThreshold: 100, // up when metric < 100
              downThreshold: 200, // down when metric > 200
              lowerIsBetter: true,
            )
            ..recordRound(80)
            ..recordRound(80);
      expect(s.level, 3); // fast → level up
      s
        ..recordRound(250)
        ..recordRound(250);
      expect(s.level, 2); // slow → level down
    });

    test('persisted streak resumes across plays', () {
      final s = make()..recordRound(90); // streak 1
      final resumed = LevelStaircase(
        level: s.level,
        min: 1,
        max: 4,
        upThreshold: 85,
        downThreshold: 60,
        streak: s.streak,
      );
      expect(resumed.recordRound(90), 1); // second qualifying round → up
    });
  });

  group('SpanStaircase (within-play)', () {
    test('+1 after two correct, tracking best', () {
      final s = SpanStaircase(level: 3, minSpan: 2)..recordTrial(correct: true);
      expect(s.best, 3);
      expect(s.level, 3);
      s.recordTrial(correct: true);
      expect(s.level, 4); // two correct → up
    });

    test('−1 after two failures, never below the floor', () {
      final s = SpanStaircase(level: 3, minSpan: 2)
        ..recordTrial(correct: false)
        ..recordTrial(correct: false);
      expect(s.level, 2);
      s
        ..recordTrial(correct: false)
        ..recordTrial(correct: false);
      expect(s.level, 2); // floor holds
    });

    test('a correct trial resets the failure counter', () {
      final s = SpanStaircase(level: 4, minSpan: 2)
        ..recordTrial(correct: false)
        ..recordTrial(correct: true) // resets failures
        ..recordTrial(correct: false);
      expect(s.level, 4); // never reached two consecutive failures
    });

    test('best holds the highest level recalled, not the current level', () {
      final s = SpanStaircase(level: 3, minSpan: 2)
        ..recordTrial(correct: true)
        ..recordTrial(correct: true) // → level 4, best 3
        ..recordTrial(correct: true); // best 4
      expect(s.best, 4);
      s
        ..recordTrial(correct: false)
        ..recordTrial(correct: false); // level back to 3
      expect(s.level, 3);
      expect(s.best, 4); // best unchanged
    });
  });
}
