import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:flutter/widgets.dart';

/// Builds a game widget, optionally driven by a [RunnerContext].
typedef GameBuilder = Widget Function({RunnerContext? runner});

/// Catalog metadata for one game (or game mode).
///
/// The Dart port of the prototype's `CS.register`. `trails` (Mode A/B) and
/// `digitspan` (forward/backward) each contribute two descriptors backed by one
/// engine via a mode flag, so the registry holds eleven entries from nine
/// engines. M6's Home and the M5/M6 runner consume it (`runnerGames`).
class GameDescriptor {
  /// Creates a descriptor.
  const GameDescriptor({
    required this.id,
    required this.title,
    required this.domain,
    required this.runnerCapable,
    required this.build,
  });

  /// Stable id used in routes (`/game/:id`), e.g. `nback`, `trails-a`.
  final String id;

  /// Display title.
  final String title;

  /// The cognitive domain this game feeds (a `Domains.*` constant).
  final String domain;

  /// Whether the baseline/session runner can drive it (`SPEC.md` §3.5).
  final bool runnerCapable;

  /// Builds the game widget (pass `runner: null` for a standalone launch).
  final GameBuilder build;
}

/// The registered games. Each game PR appends its descriptor(s); empty in the
/// foundations PR.
abstract final class GameRegistry {
  /// Every registered game/mode, in catalog order.
  static const List<GameDescriptor> all = [];

  /// The descriptor with [id], or null when unknown.
  static GameDescriptor? byId(String id) {
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// The runner-capable subset (for the M5/M6 runner).
  static List<GameDescriptor> get runnerGames =>
      all.where((g) => g.runnerCapable).toList();
}
