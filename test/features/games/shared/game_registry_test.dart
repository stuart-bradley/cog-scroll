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

    test('registers Corsi as a runner-capable Spatial Reasoning game', () {
      final corsi = GameRegistry.byId('corsi');
      expect(corsi, isNotNull);
      expect(corsi!.domain, 'Spatial Reasoning');
      expect(corsi.runnerCapable, isTrue);
    });

    test('registers Trails A & B as runner-capable Mental Flexibility', () {
      final a = GameRegistry.byId('trails-a');
      final b = GameRegistry.byId('trails-b');
      expect(a, isNotNull);
      expect(b, isNotNull);
      expect(a!.domain, 'Mental Flexibility');
      expect(b!.domain, 'Mental Flexibility');
      expect(a.runnerCapable, isTrue);
      expect(b.runnerCapable, isTrue);
    });

    test('registers Digit Span fwd & bwd as catalog-only Working Memory', () {
      final fwd = GameRegistry.byId('digitspan-fwd');
      final bwd = GameRegistry.byId('digitspan-bwd');
      expect(fwd, isNotNull);
      expect(bwd, isNotNull);
      expect(fwd!.domain, 'Working Memory');
      expect(bwd!.domain, 'Working Memory');
      expect(fwd.runnerCapable, isFalse);
      expect(bwd.runnerCapable, isFalse);
    });

    test('registers Stroop as catalog-only Attention & Inhibition', () {
      final stroop = GameRegistry.byId('stroop');
      expect(stroop, isNotNull);
      expect(stroop!.domain, 'Attention & Inhibition');
      expect(stroop.runnerCapable, isFalse);
    });

    test('registers Task Switching as catalog-only Mental Flexibility', () {
      final taskswitch = GameRegistry.byId('taskswitch');
      expect(taskswitch, isNotNull);
      expect(taskswitch!.domain, 'Mental Flexibility');
      expect(taskswitch.runnerCapable, isFalse);
    });

    test('catalog-only games are excluded from the runner subset', () {
      final runnerIds = GameRegistry.runnerGames.map((g) => g.id);
      expect(runnerIds, isNot(contains('digitspan-fwd')));
      expect(runnerIds, isNot(contains('digitspan-bwd')));
      expect(runnerIds, isNot(contains('stroop')));
      expect(runnerIds, isNot(contains('taskswitch')));
      expect(runnerIds, contains('corsi'));
      expect(runnerIds, contains('trails-a'));
      expect(runnerIds, contains('trails-b'));
    });

    test('holds all eleven M3 entries from nine engines', () {
      expect(GameRegistry.all, hasLength(11));
      // reaction, flanker, gonogo, nback, corsi + trails A/B = 7 runner picks.
      expect(GameRegistry.runnerGames, hasLength(7));
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
