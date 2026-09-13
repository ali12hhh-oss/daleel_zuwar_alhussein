import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'home_screen.dart';

/// شاشة الإقلاع: كتابة وزخرفة مرسومة برمجيًا، وليست صورة.
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
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
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

  @override
  Widget build(BuildContext context) {
    const ivory = Color(0xFFFFF4D6);
    const gold = Color(0xFFE6A83A);

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 310,
                  height: 175,
                  child: CustomPaint(
                    painter: IslamicSplashOrnament(top: true),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Text(
                    'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiriQuran(
                      color: ivory,
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'دليل الزائر',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.reemKufi(
                    color: ivory,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    shadows: const [
                      Shadow(
                        color: Color(0x55000000),
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(
                  width: 330,
                  height: 90,
                  child: CustomPaint(
                    painter: IslamicSplashOrnament(top: false),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    color: gold,
                    strokeWidth: 2.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// زخارف إسلامية هندسية مرسومة مباشرة على Canvas حتى تبقى عناصر الشاشة نصية/برمجية.
class IslamicSplashOrnament extends CustomPainter {
  final bool top;

  const IslamicSplashOrnament({required this.top});

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFE6A83A);
    final paint = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;

    if (top) {
      final arch = Path()
        ..moveTo(cx, 8)
        ..cubicTo(cx - 16, 42, cx - 105, 55, cx - 115, 105)
        ..cubicTo(cx - 145, 98, cx - 154, 125, cx - 145, 151)
        ..lineTo(cx + 145, 151)
        ..cubicTo(cx + 154, 125, cx + 145, 98, cx + 115, 105)
        ..cubicTo(cx + 105, 55, cx + 16, 42, cx, 8);
      canvas.drawPath(arch, paint);

      _diamond(canvas, Offset(cx, 8), 7, fill);
      _flower(canvas, Offset(cx, 86), 30, paint, fill);

      canvas.drawLine(const Offset(28, 151), const Offset(76, 151), paint);
      canvas.drawLine(
        Offset(size.width - 28, 151),
        Offset(size.width - 76, 151),
        paint,
      );
      _diamond(canvas, const Offset(82, 151), 5, fill);
      _diamond(canvas, Offset(size.width - 82, 151), 5, fill);
    } else {
      final y = size.height / 2;
      canvas.save();
      canvas.translate(0, y);
      canvas.drawLine(const Offset(8, 0), Offset(105, 0), paint);
      canvas.drawLine(
        Offset(size.width - 8, 0),
        Offset(size.width - 105, 0),
        paint,
      );
      _diamond(canvas, Offset(112, 0), 5, fill);
      _diamond(canvas, Offset(size.width - 112, 0), 5, fill);
      _flower(canvas, Offset(cx, 0), 27, paint, fill);
      canvas.restore();
    }
  }

  void _diamond(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _flower(
    Canvas canvas,
    Offset center,
    double r,
    Paint stroke,
    Paint fill,
  ) {
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final petalCenter = Offset(
        center.dx + r * 0.55 * math.cos(angle),
        center.dy + r * 0.55 * math.sin(angle),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: petalCenter,
          width: r * 0.75,
          height: r * 0.36,
        ),
        stroke,
      );
    }
    canvas.drawCircle(center, r * 0.23, fill);
    canvas.drawCircle(center, r * 0.45, stroke);
  }

  @override
  bool shouldRepaint(covariant IslamicSplashOrnament oldDelegate) =>
      oldDelegate.top != top;
}
