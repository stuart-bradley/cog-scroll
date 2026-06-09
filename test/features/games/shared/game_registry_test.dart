import 'package:cogscroll/features/games/shared/game_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRegistry', () {
    test('registers N-Back as a runner-capable Working Memory game', () {
      final nback = GameRegistry.byId('nback');
      expect(nback, isNotNull);
      expect(nback!.domain, 'Working Memory');
      expect(nback.runnerCapable, isTrue);
    });

    test('registers Flanker as a runner-capable Sustained Attention game', () {
      final flanker = GameRegistry.byId('flanker');
      expect(flanker, isNotNull);
      expect(flanker!.domain, 'Sustained Attention');
      expect(flanker.runnerCapable, isTrue);
    });

    test('registers Go/No-Go as a runner-capable Attention game', () {
      final gonogo = GameRegistry.byId('gonogo');
      expect(gonogo, isNotNull);
      expect(gonogo!.domain, 'Attention & Inhibition');
      expect(gonogo.runnerCapable, isTrue);
    });

    test('byId returns null for an unknown id', () {
      expect(GameRegistry.byId('does-not-exist'), isNull);
    });

    test('ids are unique', () {
      final ids = GameRegistry.all.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('runnerGames are exactly the runner-capable entries', () {
      expect(
        GameRegistry.runnerGames,
        GameRegistry.all.where((g) => g.runnerCapable).toList(),
      );
    });

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
