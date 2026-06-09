import 'package:cogscroll/features/games/shared/game_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRegistry', () {
    test('is empty in the foundations PR (game PRs append descriptors)', () {
      // Tripwire: when the first game lands this fails, prompting the invariant
      // test below to start asserting real entries instead of passing on [].
      expect(GameRegistry.all, isEmpty);
    });

    test('byId returns null for an unknown id', () {
      expect(GameRegistry.byId('does-not-exist'), isNull);
    });

    test(
      'uniqueness / byId / runnerGames invariants hold over all entries',
      () {
        final ids = GameRegistry.all.map((g) => g.id).toList();
        expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
        for (final g in GameRegistry.all) {
          expect(GameRegistry.byId(g.id), same(g));
        }
        expect(
          GameRegistry.runnerGames,
          GameRegistry.all.where((g) => g.runnerCapable).toList(),
        );
      },
    );

    test('GameDescriptor exposes its fields and builds a widget', () {
      const marker = SizedBox.shrink();
      final descriptor = GameDescriptor(
        id: 'demo',
        title: 'Demo',
        domain: 'Working Memory',
        runnerCapable: true,
        build: ({runner}) => marker,
      );
      expect(descriptor.id, 'demo');
      expect(descriptor.runnerCapable, isTrue);
      expect(descriptor.build(runner: null), same(marker));
    });
  });
}
