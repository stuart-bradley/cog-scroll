import 'dart:math';

import 'package:cogscroll/features/games/trails/domain/trails_board.dart';
import 'package:cogscroll/features/games/trails/domain/trails_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('level ladders', () {
    test('target count ladder is 8 · 12 · 16 · 20 · 25, clamped', () {
      expect(trailCountForLevel(1), 8);
      expect(trailCountForLevel(2), 12);
      expect(trailCountForLevel(3), 16);
      expect(trailCountForLevel(4), 20);
      expect(trailCountForLevel(5), 25);
      expect(trailCountForLevel(0), 8);
      expect(trailCountForLevel(9), 25);
    });

    test('dots shrink at L4–L5', () {
      expect(trailRadiusForLevel(1), 24);
      expect(trailRadiusForLevel(3), 24);
      expect(trailRadiusForLevel(4), 19);
      expect(trailRadiusForLevel(5), 19);
    });

    test('columns widen as the count grows', () {
      expect(trailColsForCount(8), 3);
      expect(trailColsForCount(12), 3);
      expect(trailColsForCount(16), 4);
      expect(trailColsForCount(20), 4);
      expect(trailColsForCount(25), 5);
    });
  });

  group('trailLabel', () {
    test('Mode A counts 1→N', () {
      expect(
        [for (var i = 0; i < 5; i++) trailLabel(i, TrailMode.a)],
        ['1', '2', '3', '4', '5'],
      );
    });

    test('Mode B alternates 1, A, 2, B, 3, C…', () {
      expect(
        [for (var i = 0; i < 8; i++) trailLabel(i, TrailMode.b)],
        ['1', 'A', '2', 'B', '3', 'C', '4', 'D'],
      );
    });

    test('Mode B at 25 targets ends on the number 13', () {
      expect(trailLabel(24, TrailMode.b), '13');
      expect(trailLabel(23, TrailMode.b), 'L');
    });
  });

  group('generateTrailTargets', () {
    test('lays out the requested count, labelled in sequence order', () {
      final targets = generateTrailTargets(
        count: 8,
        mode: TrailMode.b,
        radius: 24,
        random: Random(1),
      );
      expect(targets, hasLength(8));
      expect(
        targets.map((t) => t.label),
        ['1', 'A', '2', 'B', '3', 'C', '4', 'D'],
      );
    });

    test('every dot stays fully on the board, at every level, many seeds', () {
      for (var level = 1; level <= 5; level++) {
        final radius = trailRadiusForLevel(level);
        for (var seed = 0; seed < 20; seed++) {
          final targets = generateTrailTargets(
            count: trailCountForLevel(level),
            mode: TrailMode.a,
            radius: radius,
            random: Random(seed),
          );
          for (final t in targets) {
            expect(t.x, inInclusiveRange(radius, trailBoardW - radius));
            expect(t.y, inInclusiveRange(radius, trailBoardH - radius));
          }
        }
      }
    });

    test('no two dots overlap, even at L5 (25 crowded targets)', () {
      for (var seed = 0; seed < 20; seed++) {
        final radius = trailRadiusForLevel(5);
        final targets = generateTrailTargets(
          count: 25,
          mode: TrailMode.a,
          radius: radius,
          random: Random(seed),
        );
        for (var i = 0; i < targets.length; i++) {
          for (var j = i + 1; j < targets.length; j++) {
            final dx = targets[i].x - targets[j].x;
            final dy = targets[i].y - targets[j].y;
            expect(
              sqrt(dx * dx + dy * dy),
              greaterThanOrEqualTo(2 * radius),
              reason: 'seed $seed: dots $i and $j overlap',
            );
          }
        }
      }
    });
  });
}
