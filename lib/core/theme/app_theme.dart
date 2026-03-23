import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette - Updated with new primary colors
  static const Color primaryBlack = Color(0xFF2B2A29); // Updated from #1A1A1A
  static const Color deepBlack = Color(0xFF2B2A29); // Updated from #000000
  static const Color accentYellow = Color(0xFF67B437); // Updated from #FFD700
  static const Color vibrantYellow = Color(0xFF67B437); // Updated from #FFC107
  static const Color softGreen = Color(0xFF4CAF50);
  static const Color mintGreen = Color(0xFF81C784);
  static const Color lightGreen = Color(0xFFC8E6C9);

  // Supporting colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color darkGrey = Color(0xFF616161);
  static const Color cardGrey = Color(0xFF2A2A2A);

  // Status colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFFF5252);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color infoBlue = Color(0xFF2196F3);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentYellow,
        brightness: Brightness.light,
        primary: primaryBlack,
        secondary: accentYellow,
        tertiary: softGreen,
        surface: white,
        onPrimary: white,
        onSecondary: primaryBlack,
        onSurface: primaryBlack,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlack,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: white,
        elevation: 8,
        shadowColor: primaryBlack.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(8),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: primaryBlack,
          elevation: 4,
          shadowColor: primaryBlack.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentYellow,
        foregroundColor: primaryBlack,
        elevation: 6,
        shape: CircleBorder(),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentYellow, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryBlack,
        selectedItemColor: accentYellow,
        unselectedItemColor: darkGrey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryBlack,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: primaryBlack),
        bodyMedium: TextStyle(fontSize: 14, color: primaryBlack),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryBlack,
        ),
      ),

      // Scaffold Background
      scaffoldBackgroundColor: lightGrey,
    );
  }

  // Gradient definitions for beautiful UI
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      primaryBlack,
      Color(0xFF3A3938),
    ], // Updated gradient with new dark gray
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient yellowGradient = LinearGradient(
    colors: [accentYellow, Color(0xFF5FA030)], // Updated to green gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [softGreen, mintGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box Shadow styles
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primaryBlack.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primaryBlack.withOpacity(0.2),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];

  // Shared text styles (additions)
  static const double userNameFontSize = 16.0; // Adjusted based on feedback
  static const TextStyle userNameTextStyle = TextStyle(
    fontSize: userNameFontSize,
    fontWeight: FontWeight.w600,
    color: primaryBlack,
    height: 1.2,
  );
}
