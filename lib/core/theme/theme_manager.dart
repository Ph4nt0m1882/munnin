import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'crow_style.dart';

class ThemeManager {
  static ThemeData buildThemeData(CrowStyle style) {
    return ThemeData(
      brightness: style.ui.brightness,
      scaffoldBackgroundColor: style.ui.background,
      primaryColor: style.ui.accent,
      colorScheme: ColorScheme(
        brightness: style.ui.brightness,
        primary: style.ui.accent,
        onPrimary: style.ui.background,
        secondary: style.ui.accent,
        onSecondary: style.ui.background,
        error: Colors.redAccent,
        onError: Colors.white,
        background: style.ui.background,
        onBackground: style.ui.textPrimary,
        surface: style.ui.surface,
        onSurface: style.ui.textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: style.ui.brightness).textTheme,
      ).copyWith(
        bodyLarge: TextStyle(color: style.ui.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: style.ui.textSecondary, fontSize: 14),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: style.ui.surface,
        foregroundColor: style.ui.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: style.ui.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: style.ui.surfaceHighlight,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: style.ui.accent,
        foregroundColor: style.ui.background,
      ),
    );
  }
}
