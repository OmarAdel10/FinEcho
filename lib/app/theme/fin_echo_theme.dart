import 'package:flutter/material.dart';

/// Canonical FinEcho color tokens.
abstract final class FinEchoColors {
  /// The primary page canvas.
  static const Color canvas = Color(0xFFFFFFFF);

  /// The primary ink color.
  static const Color ink = Color(0xFF212121);

  /// The near-black text and surface color.
  static const Color nearBlack = Color(0xFF17171C);

  /// The deep-green brand surface.
  static const Color deepGreen = Color(0xFF003C33);

  /// The dark-navy brand surface.
  static const Color darkNavy = Color(0xFF071829);

  /// The soft mineral surface.
  static const Color softStone = Color(0xFFEEECE7);

  /// The pale-green accent surface.
  static const Color paleGreen = Color(0xFFEDFCE9);

  /// The primary blue accent.
  static const Color blue = Color(0xFF1863DC);

  /// The coral warning and highlight accent.
  static const Color coral = Color(0xFFFF7759);

  /// The standard divider color.
  static const Color divider = Color(0xFFD9D9DD);
}

/// Application themes built from the canonical design tokens.
abstract final class FinEchoTheme {
  /// Returns the light application theme.
  static ThemeData light() => _theme(Brightness.light);

  /// Returns the dark application theme.
  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: FinEchoColors.deepGreen,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? FinEchoColors.canvas
          : FinEchoColors.nearBlack,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: FinEchoColors.divider),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }
}
