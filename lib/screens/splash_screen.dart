import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'home_screen.dart';

/// شاشة إقلاع عربية بتصميم إسلامي متوازن، مرسومة بالكامل داخل Flutter.
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
    const ivory = Color(0xFFFFF3D2);
    const gold = Color(0xFFD7A23A);

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D5846),
              Color(0xFF0B4D3C),
              Color(0xFF083D30),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final widthScale = (constraints.maxWidth / 390).clamp(0.82, 1.16);
              final heightScale = (constraints.maxHeight / 760).clamp(0.78, 1.10);
              final scale = math.min(widthScale, heightScale).toDouble();

              return Center(
                child: SizedBox(
                  width: math.min(constraints.maxWidth * 0.88, 430.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 208 * scale,
                        child: CustomPaint(
                          painter: const SplashArchPainter(),
                        ),
                      ),
                      SizedBox(height: 5 * scale),
                      Text(
                        'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.arefRuqaaInk(
                          color: ivory,
                          fontSize: 33 * scale,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                          letterSpacing: 0.15,
                          shadows: const [
                            Shadow(
                              color: Color(0x44000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12 * scale),
                      Text(
                        'دليل الزائر',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.reemKufi(
                          color: ivory,
                          fontSize: 46 * scale,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: 0.0,
                          shadows: const [
                            Shadow(
                              color: Color(0x50000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18 * scale),
                      SizedBox(
                        height: 42 * scale,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: const SplashDividerPainter(),
                        ),
                      ),
                      SizedBox(height: 23 * scale),
                      SizedBox(
                        width: 28 * scale,
                        height: 28 * scale,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: gold,
                          backgroundColor: Color(0x222C7A63),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SplashArchPainter extends CustomPainter {
  const SplashArchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFD7A23A);
    const softGold = Color(0x9ED7A23A);
    final cx = size.width / 2;
    final bottom = size.height - 18;

    final outer = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final inner = Paint()
      ..color = softGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;

    final outerPath = Path()
      ..moveTo(cx, 8)
      ..cubicTo(cx - 18, 45, cx - 70, 57, cx - 108, 91)
      ..cubicTo(cx - 133, 114, cx - 139, 147, cx - 124, bottom)
      ..lineTo(cx + 124, bottom)
      ..cubicTo(cx + 139, 147, cx + 133, 114, cx + 108, 91)
      ..cubicTo(cx + 70, 57, cx + 18, 45, cx, 8);
    canvas.drawPath(outerPath, outer);

    final innerPath = Path()
      ..moveTo(cx, 25)
      ..cubicTo(cx - 17, 55, cx - 61, 66, cx - 91, 94)
      ..cubicTo(cx - 110, 112, cx - 116, 143, cx - 104, bottom - 17)
      ..lineTo(cx + 104, bottom - 17)
      ..cubicTo(cx + 116, 143, cx + 110, 112, cx + 91, 94)
      ..cubicTo(cx + 61, 66, cx + 17, 55, cx, 25);
    canvas.drawPath(innerPath, inner);

    _diamond(canvas, Offset(cx, 8), 5.5, fill);
    _eightPointStar(canvas, Offset(cx, 100), 22, outer, fill);
    _diamond(canvas, Offset(cx - 105, bottom), 3.5, fill);
    _diamond(canvas, Offset(cx + 105, bottom), 3.5, fill);
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

  void _eightPointStar(
    Canvas canvas,
    Offset center,
    double radius,
    Paint stroke,
    Paint fill,
  ) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final angle = -math.pi / 2 + i * math.pi / 8;
      final r = i.isEven ? radius : radius * 0.43;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, stroke);
    canvas.drawCircle(center, radius * 0.16, fill);
  }

  @override
  bool shouldRepaint(covariant SplashArchPainter oldDelegate) => false;
}

class SplashDividerPainter extends CustomPainter {
  const SplashDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFD7A23A);
    final center = Offset(size.width / 2, size.height / 2);
    final line = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;

    const centerGap = 31.0;
    const sideInset = 12.0;
    const ornamentOffset = 12.0;

    canvas.drawLine(
      Offset(sideInset, center.dy),
      Offset(center.dx - centerGap, center.dy),
      line,
    );
    canvas.drawLine(
      Offset(center.dx + centerGap, center.dy),
      Offset(size.width - sideInset, center.dy),
      line,
    );

    _diamond(canvas, Offset(sideInset + ornamentOffset, center.dy), 3.2, fill);
    _diamond(canvas, Offset(size.width - sideInset - ornamentOffset, center.dy), 3.2, fill);

    final outer = Path()
      ..moveTo(center.dx, center.dy - 13)
      ..lineTo(center.dx + 13, center.dy)
      ..lineTo(center.dx, center.dy + 13)
      ..lineTo(center.dx - 13, center.dy)
      ..close();
    canvas.drawPath(outer, line);

    final inner = Path()
      ..moveTo(center.dx, center.dy - 5.5)
      ..lineTo(center.dx + 5.5, center.dy)
      ..lineTo(center.dx, center.dy + 5.5)
      ..lineTo(center.dx - 5.5, center.dy)
      ..close();
    canvas.drawPath(inner, fill);
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

  @override
  bool shouldRepaint(covariant SplashDividerPainter oldDelegate) => false;
}
