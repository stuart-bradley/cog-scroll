import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/core/ui_kit/round_end.dart' show DeltaDirection;
import 'package:cogscroll/features/games/digitspan/domain/digit_span_state.dart';
import 'package:cogscroll/features/games/digitspan/presentation/digit_span_controller.dart';
import 'package:cogscroll/features/games/digitspan/presentation/digit_span_intro.dart';
import 'package:cogscroll/features/games/digitspan/presentation/digit_span_playing.dart';
import 'package:cogscroll/features/games/shared/game_engine.dart';
import 'package:cogscroll/features/games/shared/game_scaffold.dart';
import 'package:cogscroll/features/games/shared/round_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Digit Span (Working Memory) — catalog-only (no runner). [mode] selects
/// forward (same order) or backward (reverse order) recall; each is a separate
/// `GameRegistry` entry backed by this one screen.
class DigitSpanScreen extends ConsumerWidget {
  /// Creates the Digit Span screen for [mode].
  const DigitSpanScreen({required this.mode, super.key});

  /// Forward or backward recall.
  final DigitSpanMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = digitSpanControllerProvider(mode);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return GameScaffold(
      phase: state.phase,
      title: mode == DigitSpanMode.backward
          ? 'Digit Span · Back'
          : 'Digit Span',
      onBack: () => context.pop(),
      trailing: state.phase == GamePhase.playing
          ? Label('${state.trial + 1}/${state.trials}', color: CsTokens.fg)
          : null,
      intro: DigitSpanIntro(mode: mode, onStart: controller.start),
      playing: DigitSpanPlaying(state: state, onPad: controller.pad),
      summary: state.summary == null ? null : _roundData(state),
      onContinue: controller.start,
    );
  }

  RoundData _roundData(DigitSpanState state) {
    final summary = state.summary!;
    final spanDelta = summary.spanDelta;
    return (
      value: '${summary.span}',
      caption: 'Best span',
      sub: 'Digits recalled',
      delta: spanDelta == null || spanDelta == 0
          ? null
          : (
              dir: spanDelta > 0 ? DeltaDirection.up : DeltaDirection.down,
              text: '${spanDelta > 0 ? '+' : ''}$spanDelta vs last',
            ),
      levelMsg: null,
    );
  }
}
