import 'package:cogscroll/core/time/clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeClock', () {
    test('returns the anchored time', () {
      final clock = FakeClock(DateTime.utc(2026, 6, 9, 12));
      expect(clock.now(), DateTime.utc(2026, 6, 9, 12));
    });

    test('advance moves time forward by the duration', () {
      final clock = FakeClock(DateTime.utc(2026))
        ..advance(const Duration(hours: 1, minutes: 30));
      expect(clock.now(), DateTime.utc(2026, 1, 1, 1, 30));
    });

    test('advance accumulates across calls', () {
      final clock = FakeClock(DateTime.utc(2026))
        ..advance(const Duration(days: 1))
        ..advance(const Duration(days: 27));
      expect(clock.now(), DateTime.utc(2026, 1, 29));
    });

    test('setTime replaces the current time', () {
      final clock = FakeClock(DateTime.utc(2026))..setTime(DateTime.utc(2027));
      expect(clock.now(), DateTime.utc(2027));
    });
  });

  group('SystemClock', () {
    test('now sits between two real reads', () {
      const clock = SystemClock();
      final before = DateTime.now();
      final t = clock.now();
      final after = DateTime.now();
      expect(t.isBefore(before), isFalse);
      expect(t.isAfter(after), isFalse);
    });
  });
}
