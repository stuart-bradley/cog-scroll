import 'package:cogscroll/core/storage/cs_store_keys.dart';
import 'package:cogscroll/core/storage/cs_store_provider.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:cogscroll/core/ui_kit/label.dart';
import 'package:cogscroll/features/baseline/presentation/baseline_runner_screen.dart';
import 'package:cogscroll/features/dashboard/presentation/dashboard_screen.dart';
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
/// `/` is the throwaway [DevCatalogScreen] (replaced by M6's Home); `/game/:id`
/// launches a registered game standalone (`runner: null`); `/baseline` is the
/// M5 onboarding runner. A first-run `redirect` sends unprompted launches to
/// the baseline.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    // First-run gate: force a launch that has never seen the baseline prompt to
    // `/baseline`. One-directional — it never redirects *away* from an
    // explicit `/baseline`, so once `baselinePrompted` is set (on flow open),
    // the dev "Run baseline" link still works and there is no loop. Re-read on
    // each navigation; `baselinePrompted` is set on entry, navigation on exit.
    redirect: (context, state) {
      final prompted =
          ref.read(csStoreProvider).getBool(CsStoreKeys.baselinePrompted) ??
          false;
      if (!prompted && state.matchedLocation != '/baseline') return '/baseline';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DevCatalogScreen(),
      ),
      GoRoute(
        path: '/baseline',
        builder: (context, state) => const BaselineRunnerScreen(),
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
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
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
