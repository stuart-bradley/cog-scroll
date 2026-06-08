import 'package:cogscroll/features/home/presentation/home_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Provides the app [GoRouter].
///
/// Kept alive so navigation state survives provider rebuilds and the router is
/// not torn down between widget-test frame pumps. Routes grow per milestone;
/// for M0 there is a single placeholder home route.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
