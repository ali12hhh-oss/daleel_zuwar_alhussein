import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DaleelZuwarApp());
}

class DaleelZuwarApp extends StatefulWidget {
  const DaleelZuwarApp({super.key});

  @override
  State<DaleelZuwarApp> createState() => _DaleelZuwarAppState();
}

class _DaleelZuwarAppState extends State<DaleelZuwarApp> {
  // الوضع الافتراضي: يتبع إعدادات الجهاز (نهاري/ليلي)، ويمكن للمستخدم تبديله يدوياً
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        // إن كان يتبع النظام، اجعل أول ضغطة تنتقل إلى الوضع الليلي مباشرة
        _themeMode = ThemeMode.dark;
      }
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
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [Locale('ar', 'IQ')],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: HomeScreen(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
