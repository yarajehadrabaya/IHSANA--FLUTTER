import 'package:flutter/material.dart';

class AppTheme {
  // 🎨 Colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color background = Color(0xFFF8FAFF);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFCBD5E1);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color error = Color(0xFFDC2626);

  // 🔤 Typography (Senior-friendly)
  static final TextTheme textTheme = TextTheme(
    headlineLarge: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: textPrimary,
    ),
    headlineMedium: const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: textPrimary,
    ),
    bodyLarge: const TextStyle(
      fontSize: 18,
      color: textPrimary,
    ),
    bodyMedium: const TextStyle(
      fontSize: 16,
      color: textSecondary,
    ),
    labelLarge: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );

  // 🧩 Inputs
  static final InputDecorationTheme inputDecorationTheme =
      InputDecorationTheme(
    filled: true,
    fillColor: surface,
    labelStyle: const TextStyle(fontSize: 16),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: error),
    ),
  );

  // 🔘 Buttons (واضحة لكبار السن)
  static final ElevatedButtonThemeData elevatedButtonTheme =
      ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // 🧱 Cards
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.08),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );

  // 🌗 Theme
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    textTheme: textTheme,
    inputDecorationTheme: inputDecorationTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    colorScheme: const ColorScheme.light(
      primary: primary,
      error: error,
    ),
  );
}
