import 'package:cogscroll/core/theme/app_typography.dart';
import 'package:cogscroll/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Placeholder home screen for the M0 scaffold.
///
/// Proves the theme + font pipeline boots; replaced by the real Home (Today
/// hero + catalog of nine games) in M6.
class HomeScreen extends StatelessWidget {
  /// Creates the placeholder home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CsTokens.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'CogScroll',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text('BRAIN TRAINING', style: CsType.microLabel),
          ],
        ),
      ),
    );
  }
}
