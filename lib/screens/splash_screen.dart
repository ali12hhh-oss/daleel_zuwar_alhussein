import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme.dart';
import 'home_screen.dart';

/// ✅ شاشة تظهر لمدة 3 ثوانٍ عند فتح التطبيق: خلفية خضراء + صورة ضريح
/// الإمام الحسين (ع) + صوت افتتاحي، ثم تنتقل تلقائياً للشاشة الرئيسية.
class SplashScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const SplashScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playOpeningSound();
    _navigateAfterDelay();
  }

  /// ✅ تشغيل صوت الافتتاح. الصوت مدته 10 ثوانٍ بينما شاشة splash تدوم
  /// 3 ثوانٍ فقط - لذلك لا نوقف الصوت عند الانتقال للشاشة الرئيسية، بل
  /// نتركه يكمل تشغيله بالخلفية، ويتخلّص من نفسه تلقائياً (dispose) فور
  /// انتهائه فعلياً عبر onPlayerComplete بدل ربطه بدورة حياة هذه الشاشة.
  Future<void> _playOpeningSound() async {
    try {
      _audioPlayer.onPlayerComplete.listen((_) {
        _audioPlayer.dispose();
      });
      await _audioPlayer.play(AssetSource('sounds/splash_sound.mp3'));
    } catch (_) {
      // تجاهل: الصوت غير حرج لعمل التطبيق
    }
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          themeMode: widget.themeMode,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
  }

  // ملاحظة: تعمّدنا عدم استدعاء _audioPlayer.dispose() هنا داخل
  // dispose() الخاص بالـ State، لأن ذلك كان سيقطع الصوت فوراً عند
  // مغادرة شاشة splash (بعد 3 ثوانٍ فقط) رغم أن الصوت مدته 10 ثوانٍ.
  // التخلص من المشغّل يحدث تلقائياً في onPlayerComplete أعلاه.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ نفس اللون الأخضر المستخدم في هوية التطبيق (AppColors.primaryGreen)
      // للحفاظ على نفس مظهر الشاشة الخضراء الافتراضية قبل هذا التعديل
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/hussain_shrine.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'دليل الزائر',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white70,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
