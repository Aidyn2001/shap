import 'package:flutter/material.dart';

/// Shap brand palette.
class ShapColors {
  static const primary = Color(0xFF5B21B6);   // Primary Purple
  static const deep = Color(0xFF3B0764);      // Deep Purple
  static const neon = Color(0xFFA855F7);      // Neon Accent
  static const success = Color(0xFF00C853);   // Success Green
  static const dark = Color(0xFF140021);      // Dark Background
  static const surface = Color(0xFF1E0733);
  static const onDark = Color(0xFFEDE9FE);
}

class ShapTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: ShapColors.dark,
      colorScheme: const ColorScheme.dark(
        primary: ShapColors.primary,
        secondary: ShapColors.neon,
        surface: ShapColors.surface,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ShapColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ShapColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
