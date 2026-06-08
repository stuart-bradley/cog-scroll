import 'package:cogscroll/core/routing/app_router.dart';
import 'package:cogscroll/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entry point for the CogScroll application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ProviderScope(child: CogScrollApp()));
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
