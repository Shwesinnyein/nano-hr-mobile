import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFC19A6B); // New theme color
  static const Color secondaryColor = Color(0xFF10B981); // Green
  static const Color errorColor = Color(0xFFEF4444); // Red
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color successColor = Color(0xFF10B981); // Green
  static const Color kSkyBlue = Color(0xFFC19A6B); // New theme color
  static const Color kSkyBlueDark = Color(0xFFA67C4A); // Darker version
  static const Color kSkyBlueLight = Color(0xFFE6D4B8); // Light version

  static const Color kCamelNude = Color(0xFFC19A6B);
  static const Color kWarmBeige = Color(0xFFC7A27B);

  static const Color kBackground = Color(0xFFF7FBFD);
  static const Color kSurface = Color(0xFFFFFFFF);

  static const Color kOnPrimary = Color(0xFF1C1C1C);
  static const Color kOnSecondary = Color(0xFFFFFFFF);
  static const Color kOnBackground = Color(0xFF2C2C2C);
  static const Color kOnSurface = Color(0xFF2C2C2C);
  static const Color kNanoBlack = Color(0xFF121212);
  static const Color kNanoGoldLight = Color(
    0xFFE6D4B8,
  ); // Light version of new color
  static const Color kNanoGold = Color(0xFFC19A6B); // New theme color
  static const Color kNanoGoldDark = Color(0xFFA67C4A); // Darker version
  static const Color kNanoWhite = Color(0xFFFFFFFF);

  // Professional color palette
  static const Color kNavyBlue = Color(0xFF1E3A8A);
  static const Color kNavyBlueDark = Color(0xFF1E40AF);
  static const Color kCharcoal = Color(0xFF374151);
  static const Color kCharcoalDark = Color(0xFF1F2937);
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kSkyBlue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: kBackground,
        foregroundColor: kBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kSkyBlue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: kBackground,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
