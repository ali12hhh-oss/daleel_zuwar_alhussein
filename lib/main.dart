import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuranLibrary.init();
  runApp(const DaleelApp());
}

class DaleelApp extends StatefulWidget {
  const DaleelApp({super.key});

  @override
  State<DaleelApp> createState() => _DaleelAppState();
}

class _DaleelAppState extends State<DaleelApp> {
  ThemeMode _themeMode = ThemeMode.light;

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
      home: HomeScreen(
        themeMode: _themeMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}
