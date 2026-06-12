import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/features/baseline/domain/baseline_set.dart';
import 'package:cogscroll/features/games/shared/game_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('is the six baseline games in fixed order', () {
    expect(
      baselineSet.map((s) => s.id).toList(),
      ['reaction', 'flanker', 'gonogo', 'nback', 'corsi', 'trails-a'],
    );
  });

  test('every step resolves to a runner-capable registry game', () {
    for (final step in baselineSet) {
      final game = GameRegistry.byId(step.id);
      expect(game, isNotNull, reason: '${step.id} must exist in the registry');
      expect(
        game!.runnerCapable,
        isTrue,
        reason: '${step.id} must be runner-capable',
      );
    }
  });

  test('each step sets exactly one abbreviated length', () {
    for (final step in baselineSet) {
      expect(
        (step.trials == null) != (step.points == null),
        isTrue,
        reason: '${step.id} must set exactly one of trials / points',
      );
    }
  });

  test('the steps cover all six domains, each once', () {
    final domains = baselineSet
        .map((s) => GameRegistry.byId(s.id)!.domain)
        .toSet();
    expect(domains, Domains.all.toSet());
    expect(baselineSet.length, Domains.all.length);
  });
}
