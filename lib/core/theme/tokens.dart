import 'package:flutter/widgets.dart';

/// Fixed pure-mono design tokens for CogScroll.
///
/// Ported 1:1 from the prototype's `T` object (DESIGN §2 / SPEC §3.6). The app
/// uses no colour anywhere — correctness is never carried by hue.
abstract final class CsTokens {
  /// Surface / ground — pure white.
  static const Color bg = Color(0xFFFFFFFF);

  /// Ink — near-black, used for text, shapes, and fills.
  static const Color fg = Color(0xFF111111);

  /// Secondary text (`fg` at 42% opacity).
  static const Color sub = Color(0x6B111111);

  /// Hints / disabled (`fg` at 20% opacity).
  static const Color faint = Color(0x33111111);

  /// Hairlines / idle cells (`fg` at 14% opacity).
  static const Color line = Color(0x24111111);

  /// Inset wells — keypad, idle grid cells.
  static const Color panel = Color(0xFFF4F4F4);

  /// Corner radius for pills and cards.
  static const double radius = 16;
}
