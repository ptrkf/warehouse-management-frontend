import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color secondaryGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 2,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
  );
}