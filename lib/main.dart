import 'package:cogscroll/core/routing/app_router.dart';
import 'package:cogscroll/core/storage/cs_store.dart';
import 'package:cogscroll/core/storage/cs_store_provider.dart';
import 'package:cogscroll/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entry point for the CogScroll application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Resolve the store eagerly so engines read per-game state synchronously.
  final store = CsStore(await SharedPreferences.getInstance());
  runApp(
    ProviderScope(
      overrides: [csStoreProvider.overrideWithValue(store)],
      child: const CogScrollApp(),
    ),
  );
}

/// Root widget for CogScroll.
class CogScrollApp extends ConsumerWidget {
  /// Creates the root [CogScrollApp].
  const CogScrollApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'CogScroll',
      theme: CsTheme.theme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
