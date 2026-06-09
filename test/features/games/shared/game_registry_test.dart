import 'package:cogscroll/features/games/shared/game_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRegistry', () {
    test('ids are unique', () {
      final ids = GameRegistry.all.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('byId returns null for an unknown id', () {
      expect(GameRegistry.byId('does-not-exist'), isNull);
    });

    test('byId finds a registered descriptor by id', () {
      for (final g in GameRegistry.all) {
        expect(GameRegistry.byId(g.id), same(g));
      }
    });

    test('runnerGames are exactly the runner-capable entries', () {
      expect(
        GameRegistry.runnerGames,
        GameRegistry.all.where((g) => g.runnerCapable).toList(),
      );
    });
  });
}
