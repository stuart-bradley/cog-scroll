import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/features/games/shared/game_registry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Temporary developer catalog — the app's `/` screen for M3.
///
/// Replaces the M0 placeholder Home and is itself superseded by M6's real Home
/// (Today hero + grouped catalog). Shows the wordmark then a tappable list of
/// every registered game; a tap launches `/game/:id`. Empty until games land,
/// so it reads from the same [GameRegistry] M6's Home will.
class DevCatalogScreen extends StatelessWidget {
  /// Creates the dev catalog screen.
  const DevCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final games = GameRegistry.all;
    return Scaffold(
      backgroundColor: CsTokens.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 36, 30, 4),
              child: Text(
                'CogScroll',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(30, 0, 30, 24),
              child: Text('BRAIN TRAINING', style: CsType.microLabel),
            ),
            Expanded(
              child: games.isEmpty
                  ? const Center(child: Label('NO GAMES YET'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      itemCount: games.length,
                      itemBuilder: (context, i) => _CatalogRow(
                        game: games[i],
                        onTap: () => context.push('/game/${games[i].id}'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogRow extends StatelessWidget {
  const _CatalogRow({required this.game, required this.onTap});

  final GameDescriptor game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                game.title,
                style: const TextStyle(
                  fontFamily: CsType.family,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                  color: CsTokens.fg,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Label(game.domain),
          ],
        ),
      ),
    );
  }
}
