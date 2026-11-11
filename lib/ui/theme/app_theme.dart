import 'package:flutter/material.dart';

class AppTheme {
  static const Color _surface = Color(0xFF111111);
  static const Color _surfaceVariant = Color(0xFF292929);
  static const Color _accent = Color(0xFFEF3545);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: _surface,
      colorScheme: base.colorScheme.copyWith(
        primary: _accent,
        onPrimary: _surface,
        secondaryContainer: _surfaceVariant,
        onSecondaryContainer: const Color(0xFFE3EDF3),
        secondary: _accent,
        surface: _surface,
        surfaceContainerHighest: _surfaceVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF191919),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
