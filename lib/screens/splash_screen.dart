import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'home_screen.dart';

/// شاشة إقلاع عربية بطابع إسلامي، مرسومة بالكامل داخل Flutter.
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
    const gold = Color(0xFFD9A441);
    final scale = (MediaQuery.sizeOf(context).width / 390)
        .clamp(0.82, 1.12)
        .toDouble();

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D5745),
              Color(0xFF0B4D3C),
              Color(0xFF083D30),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 330 * scale,
                    height: 170 * scale,
                    child: CustomPaint(
                      painter: const IslamicSplashOrnament(),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -18 * scale),
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiriQuran(
                        color: ivory,
                        fontSize: 29 * scale,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18 * scale),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'دليل الزائر',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.reemKufi(
                          color: ivory,
                          fontSize: 49 * scale,
                          fontWeight: FontWeight.w700,
                          height: 1.12,
                          letterSpacing: 0.2,
                          shadows: const [
                            Shadow(
                              color: Color(0x66000000),
                              blurRadius: 7,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14 * scale),
                  SizedBox(
                    width: 330 * scale,
                    height: 54 * scale,
                    child: CustomPaint(
                      painter: const SplashDividerPainter(),
                    ),
                  ),
                  SizedBox(height: 22 * scale),
                  SizedBox(
                    width: 30 * scale,
                    height: 30 * scale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: gold,
                      backgroundColor: Color(0x332C7A63),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class IslamicSplashOrnament extends CustomPainter {
  const IslamicSplashOrnament();

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFD9A441);
    const softGold = Color(0xB8D9A441);
    final cx = size.width / 2;
    final stroke = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final softStroke = Paint()
      ..color = softGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final fill = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;

    final arch = Path()
      ..moveTo(cx, 7)
      ..cubicTo(cx - 10, 38, cx - 74, 43, cx - 101, 76)
      ..cubicTo(cx - 119, 98, cx - 119, 123, cx - 109, 150)
      ..lineTo(cx + 109, 150)
      ..cubicTo(cx + 119, 123, cx + 119, 98, cx + 101, 76)
      ..cubicTo(cx + 74, 43, cx + 10, 38, cx, 7);
    canvas.drawPath(arch, stroke);

    final inner = Path()
      ..moveTo(cx, 19)
      ..cubicTo(cx - 14, 48, cx - 62, 52, cx - 84, 81)
      ..cubicTo(cx - 99, 100, cx - 98, 122, cx - 91, 139)
      ..lineTo(cx + 91, 139)
      ..cubicTo(cx + 98, 122, cx + 99, 100, cx + 84, 81)
      ..cubicTo(cx + 62, 52, cx + 14, 48, cx, 19);
    canvas.drawPath(inner, softStroke);

    _diamond(canvas, Offset(cx, 8), 5.5, fill);
    _rosette(canvas, Offset(cx, 88), 25, stroke, fill);

    canvas.drawLine(const Offset(18, 150), Offset(72, 150), stroke);
    canvas.drawLine(
      Offset(size.width - 18, 150),
      Offset(size.width - 72, 150),
      stroke,
    );
    _diamond(canvas, const Offset(78, 150), 4, fill);
    _diamond(canvas, Offset(size.width - 78, 150), 4, fill);
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

  void _rosette(
    Canvas canvas,
    Offset center,
    double radius,
    Paint stroke,
    Paint fill,
  ) {
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final petal = Offset(
        center.dx + radius * 0.53 * math.cos(angle),
        center.dy + radius * 0.53 * math.sin(angle),
      );
      canvas.save();
      canvas.translate(petal.dx, petal.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 0.70,
          height: radius * 0.32,
        ),
        stroke,
      );
      canvas.restore();
    }
    canvas.drawCircle(center, radius * 0.20, fill);
    canvas.drawCircle(center, radius * 0.42, stroke);
  }

  @override
  bool shouldRepaint(covariant IslamicSplashOrnament oldDelegate) => false;
}

class SplashDividerPainter extends CustomPainter {
  const SplashDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFD9A441);
    final center = Offset(size.width / 2, size.height / 2);
    final line = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      const Offset(8, 27),
      Offset(center.dx - 39, center.dy),
      line,
    );
    canvas.drawLine(
      Offset(center.dx + 39, center.dy),
      Offset(size.width - 8, center.dy),
      line,
    );
    _diamond(canvas, Offset(31, center.dy), 3.5, fill);
    _diamond(canvas, Offset(size.width - 31, center.dy), 3.5, fill);

    final outer = Path()
      ..moveTo(center.dx, center.dy - 15)
      ..lineTo(center.dx + 15, center.dy)
      ..lineTo(center.dx, center.dy + 15)
      ..lineTo(center.dx - 15, center.dy)
      ..close();
    canvas.drawPath(outer, line);

    final inner = Path()
      ..moveTo(center.dx, center.dy - 6)
      ..lineTo(center.dx + 6, center.dy)
      ..lineTo(center.dx, center.dy + 6)
      ..lineTo(center.dx - 6, center.dy)
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
