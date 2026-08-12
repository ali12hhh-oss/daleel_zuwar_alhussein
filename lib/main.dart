import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  runApp(const DaleelApp());
}

class DaleelApp extends StatefulWidget {
  const DaleelApp({super.key});
  @override
  State<DaleelApp> createState() => _DaleelAppState();
}

class _DaleelAppState extends State<DaleelApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دليل زوار الحسين',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: _themeMode,
      // ✅ نبدأ الآن من شاشة splash (صورة الضريح + صوت + 3 ثوانٍ)
      // بدل فتح الشاشة الرئيسية مباشرة
      home: SplashScreen(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
