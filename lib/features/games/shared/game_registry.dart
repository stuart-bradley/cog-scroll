import 'package:cogscroll/core/analytics/domains.dart';
import 'package:cogscroll/features/games/corsi/presentation/corsi_screen.dart';
import 'package:cogscroll/features/games/digitspan/domain/digit_span_state.dart';
import 'package:cogscroll/features/games/digitspan/presentation/digit_span_screen.dart';
import 'package:cogscroll/features/games/flanker/presentation/flanker_screen.dart';
import 'package:cogscroll/features/games/gonogo/presentation/gonogo_screen.dart';
import 'package:cogscroll/features/games/nback/presentation/nback_screen.dart';
import 'package:cogscroll/features/games/reaction/presentation/reaction_screen.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/stroop/presentation/stroop_screen.dart';
import 'package:cogscroll/features/games/taskswitch/presentation/taskswitch_screen.dart';
import 'package:cogscroll/features/games/trails/domain/trails_state.dart';
import 'package:cogscroll/features/games/trails/presentation/trails_screen.dart';
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

/// The registered games. Each game PR appends its descriptor(s).
abstract final class GameRegistry {
  /// Every registered game/mode, in catalog order. Not `const` — each
  /// descriptor's `build` is a closure.
  static final List<GameDescriptor> all = [
    GameDescriptor(
      id: 'nback',
      title: 'N-Back',
      domain: Domains.workingMemory,
      runnerCapable: true,
      build: ({runner}) => NbackScreen(runner: runner),
    ),
    GameDescriptor(
      id: 'reaction',
      title: 'Reaction Time',
      domain: Domains.processingSpeed,
      runnerCapable: true,
      build: ({runner}) => ReactionScreen(runner: runner),
    ),
    GameDescriptor(
      id: 'flanker',
      title: 'Flanker',
      domain: Domains.sustainedAttention,
      runnerCapable: true,
      build: ({runner}) => FlankerScreen(runner: runner),
    ),
    GameDescriptor(
      id: 'gonogo',
      title: 'Go / No-Go',
      domain: Domains.attentionInhibition,
      runnerCapable: true,
      build: ({runner}) => GoNoGoScreen(runner: runner),
    ),
    GameDescriptor(
      id: 'corsi',
      title: 'Spatial Grid',
      domain: Domains.spatialReasoning,
      runnerCapable: true,
      build: ({runner}) => CorsiScreen(runner: runner),
    ),
    // Trail Making: one engine, two runner-capable entries (Mode A / Mode B).
    GameDescriptor(
      id: 'trails-a',
      title: 'Trail Making',
      domain: Domains.mentalFlexibility,
      runnerCapable: true,
      build: ({runner}) => TrailsScreen(mode: TrailMode.a, runner: runner),
    ),
    GameDescriptor(
      id: 'trails-b',
      title: 'Trail Making · Letters',
      domain: Domains.mentalFlexibility,
      runnerCapable: true,
      build: ({runner}) => TrailsScreen(mode: TrailMode.b, runner: runner),
    ),
    // Digit Span: one engine, two catalog-only entries (forward / backward).
    GameDescriptor(
      id: 'digitspan-fwd',
      title: 'Digit Span',
      domain: Domains.workingMemory,
      runnerCapable: false,
      build: ({runner}) => const DigitSpanScreen(mode: DigitSpanMode.forward),
    ),
    GameDescriptor(
      id: 'digitspan-bwd',
      title: 'Digit Span · Backward',
      domain: Domains.workingMemory,
      runnerCapable: false,
      build: ({runner}) => const DigitSpanScreen(mode: DigitSpanMode.backward),
    ),
    // Stroop: catalog-only (interference-cost metric, not runner-driven).
    GameDescriptor(
      id: 'stroop',
      title: 'Stroop',
      domain: Domains.attentionInhibition,
      runnerCapable: false,
      build: ({runner}) => const StroopScreen(),
    ),
    // Task Switching: catalog-only (shape / fill / size rule rotation).
    GameDescriptor(
      id: 'taskswitch',
      title: 'Task Switching',
      domain: Domains.mentalFlexibility,
      runnerCapable: false,
      build: ({runner}) => const TaskSwitchScreen(),
    ),
  ];

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
