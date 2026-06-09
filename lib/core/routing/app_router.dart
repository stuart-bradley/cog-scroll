import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/features/games/shared/game_registry.dart';
import 'package:cogscroll/features/home/presentation/dev_catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Provides the app [GoRouter].
///
/// Kept alive so navigation state survives provider rebuilds and the router is
/// not torn down between widget-test frame pumps. Routes grow per milestone.
/// For M3: `/` is the throwaway [DevCatalogScreen] (replaced by M6's Home) and
/// `/game/:id` launches a registered game standalone (`runner: null`); the
/// M5/M6 runner mounts game widgets directly rather than via this route.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DevCatalogScreen(),
      ),
      GoRoute(
        path: '/game/:id',
        builder: (context, state) {
          final game = GameRegistry.byId(state.pathParameters['id'] ?? '');
          return game == null
              ? const _UnknownGameScreen()
              : game.build(runner: null);
        },
      ),
    ],
  );
}

/// Fallback for a `/game/:id` with no matching registry entry.
class _UnknownGameScreen extends StatelessWidget {
  const _UnknownGameScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: CsTokens.bg,
      body: SafeArea(child: Center(child: Label('UNKNOWN GAME'))),
    );
  }
}
