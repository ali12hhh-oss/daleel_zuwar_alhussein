import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// هوية بصرية للتطبيق: أخضر حسيني داكن + ذهبي، مع دعم وضعين نهاري وليلي
class AppColors {
  static const Color primaryGreen = Color(0xFF0B4D3C);
  static const Color deepGreen = Color(0xFF073A2C);
  static const Color gold = Color(0xFFC9A227);
  static const Color lightGold = Color(0xFFE9D9A0);

  // وضع نهاري
  static const Color lightBackground = Color(0xFFF7F5EF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF222222);

  // وضع ليلي
  static const Color darkBackground = Color(0xFF0E1512);
  static const Color darkCard = Color(0xFF162420);
  static const Color darkText = Color(0xFFEFEAD9);
}

ThemeData buildLightTheme() {
  final baseTextTheme = GoogleFonts.notoNaskhArabicTextTheme();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBackground,
    primaryColor: AppColors.primaryGreen,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryGreen,
      brightness: Brightness.light,
      primary: AppColors.primaryGreen,
      secondary: AppColors.gold,
      surface: AppColors.lightCard,
    ),
    textTheme: baseTextTheme.apply(
      bodyColor: AppColors.lightText,
      displayColor: AppColors.lightText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.notoNaskhArabic(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardTheme( // ✅ CardTheme بدل CardThemeData
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.lightCard,
    ),
    fontFamily: GoogleFonts.notoNaskhArabic().fontFamily,
  );
}

ThemeData buildDarkTheme() {
  final baseTextTheme = GoogleFonts.notoNaskhArabicTextTheme();
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.gold,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.dark,
      primary: AppColors.gold,
      secondary: AppColors.primaryGreen,
      surface: AppColors.darkCard,
    ),
    textTheme: baseTextTheme.apply(
      bodyColor: AppColors.darkText,
      displayColor: AppColors.darkText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkCard,
      foregroundColor: AppColors.darkText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.notoNaskhArabic(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
    ),
    cardTheme: CardTheme( // ✅ CardTheme بدل CardThemeData
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.darkCard,
    ),
    fontFamily: GoogleFonts.notoNaskhArabic().fontFamily,
  );
}
