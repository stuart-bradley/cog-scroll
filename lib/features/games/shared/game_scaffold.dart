import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart';
import 'package:cogscroll/core/ui_kit/top_bar.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:cogscroll/features/games/shared/runner_context.dart';
import 'package:cogscroll/features/games/shared/runner_header.dart';
import 'package:flutter/material.dart';

/// Shared chrome for a game screen.
///
/// Routes [intro] → [playing] → round, and **hides the TopBar and RoundEnd when
/// a [runner] is present** (the runner draws its own header and advances on
/// `onDone`, so the game never reaches a visible round). In standalone mode the
/// round phase renders the shared `RoundEnd` from [summary]. Per-game widgets
/// supply the [intro] / [playing] slots; the substantial bespoke UI is
/// [playing].
class GameScaffold extends StatelessWidget {
  /// Creates a game scaffold.
  const GameScaffold({
    required this.phase,
    required this.title,
    required this.intro,
    required this.playing,
    this.runner,
    this.summary,
    this.continueLabel = 'Continue',
    this.onContinue,
    this.onBack,
    this.trailing,
    super.key,
  });

  /// The current engine phase.
  final GamePhase phase;

  /// Game title for the TopBar (standalone only).
  final String title;

  /// The intro screen (typically wraps the shared `Intro`).
  final Widget intro;

  /// The bespoke play UI.
  final Widget playing;

  /// Runner context when driven by the runner; null standalone.
  final RunnerContext? runner;

  /// Round-end summary (standalone only; null until `finish()`).
  final RoundData? summary;

  /// Continue button label on the round screen.
  final String continueLabel;

  /// Continue handler on the round screen.
  final VoidCallback? onContinue;

  /// Back handler for the TopBar (standalone only).
  final VoidCallback? onBack;

  /// Optional TopBar trailing chrome (e.g. a level label).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final r = runner;
    return Scaffold(
      backgroundColor: CsTokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            // The runner draws a unified header (progress + Skip + Exit) in
            // place of the standalone TopBar.
            if (r != null)
              RunnerHeader(r)
            else
              TopBar(title: title, onBack: onBack, trailing: trailing),
            Expanded(child: _body(inRunner: r != null)),
          ],
        ),
      ),
    );
  }

  Widget _body({required bool inRunner}) {
    switch (phase) {
      case GamePhase.intro:
        return intro;
      case GamePhase.playing:
        return playing;
      case GamePhase.round:
        // Under a runner, finish() already called onDone — nothing to show.
        final s = summary;
        if (inRunner || s == null) return const SizedBox.shrink();
        return RoundEnd(
          value: s.value,
          caption: s.caption,
          sub: s.sub,
          delta: s.delta,
          levelMsg: s.levelMsg,
          continueLabel: continueLabel,
          onContinue: onContinue,
        );
    }
  }
}
