import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'home_screen.dart';

/// شاشة الإقلاع: النص والزخارف مرسومة برمجيًا، بدون استخدام صورة التصميم.
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
    const gold = Color(0xFFE7AE4A);

    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 350,
                  height: 185,
                  child: CustomPaint(
                    painter: IslamicSplashOrnament(top: true),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: SizedBox(
                    width: 360,
                    height: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned.fill(
                          child: CustomPaint(
                            painter: BismillahFlourishPainter(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiriQuran(
                                color: ivory,
                                fontSize: 39,
                                fontWeight: FontWeight.w400,
                                height: 1.05,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
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
                const SizedBox(height: 5),
                const SizedBox(
                  width: 350,
                  height: 95,
                  child: CustomPaint(
                    painter: IslamicSplashOrnament(top: false),
                  ),
                ),
                const SizedBox(height: 14),
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: gold,
                    strokeWidth: 3.2,
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

/// القوس العلوي والزخرفة العربية المركزية.
class IslamicSplashOrnament extends CustomPainter {
  final bool top;

  const IslamicSplashOrnament({required this.top});

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFE7AE4A);
    final stroke = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = top ? 2.5 : 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final thin = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;

    if (top) {
      final arch = Path()
        ..moveTo(cx, 8)
        ..cubicTo(cx - 22, 38, cx - 42, 45, cx - 82, 63)
        ..cubicTo(cx - 119, 80, cx - 132, 103, cx - 136, 124)
        ..cubicTo(cx - 157, 120, cx - 171, 133, cx - 172, 153)
        ..cubicTo(cx - 173, 169, cx - 168, 180, cx - 163, 181)
        ..lineTo(cx + 163, 181)
        ..cubicTo(cx + 168, 180, cx + 173, 169, cx + 172, 153)
        ..cubicTo(cx + 171, 133, cx + 157, 120, cx + 136, 124)
        ..cubicTo(cx + 132, 103, cx + 119, 80, cx + 82, 63)
        ..cubicTo(cx + 42, 45, cx + 22, 38, cx, 8);
      canvas.drawPath(arch, stroke);

      _ornamentalTip(canvas, Offset(cx, 8), 10, fill, stroke);
      _arabesque(canvas, Offset(cx, 91), 34, stroke, thin, fill);

      canvas.drawLine(const Offset(30, 181), const Offset(72, 181), stroke);
      canvas.drawLine(
        Offset(size.width - 30, 181),
        Offset(size.width - 72, 181),
        stroke,
      );
      _diamond(canvas, const Offset(78, 181), 5.5, fill);
      _diamond(canvas, Offset(size.width - 78, 181), 5.5, fill);
    } else {
      final y = size.height / 2;
      canvas.save();
      canvas.translate(0, y);
      canvas.drawLine(const Offset(10, 0), const Offset(105, 0), stroke);
      canvas.drawLine(
        Offset(size.width - 10, 0),
        Offset(size.width - 105, 0),
        stroke,
      );
      _diamond(canvas, Offset(113, 0), 5.5, fill);
      _diamond(canvas, Offset(size.width - 113, 0), 5.5, fill);
      _eightPetalMedallion(canvas, Offset(cx, 0), 33, stroke, thin, fill);
      canvas.restore();
    }
  }

  void _ornamentalTip(
    Canvas canvas,
    Offset center,
    double r,
    Paint fill,
    Paint stroke,
  ) {
    final p = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r * .48, center.dy - r * .25)
      ..lineTo(center.dx + r * .2, center.dy + r * .15)
      ..lineTo(center.dx, center.dy + r * .65)
      ..lineTo(center.dx - r * .2, center.dy + r * .15)
      ..lineTo(center.dx - r * .48, center.dy - r * .25)
      ..close();
    canvas.drawPath(p, fill);
    canvas.drawPath(p, stroke);
  }

  void _arabesque(
    Canvas canvas,
    Offset c,
    double r,
    Paint stroke,
    Paint thin,
    Paint fill,
  ) {
    final left = Path()
      ..moveTo(c.dx, c.dy + r)
      ..cubicTo(c.dx - 8, c.dy + r * .55, c.dx - 8, c.dy + 8, c.dx - 2, c.dy + 1)
      ..cubicTo(c.dx - 17, c.dy - 13, c.dx - 22, c.dy - 25, c.dx - 10, c.dy - 29)
      ..cubicTo(c.dx - 2, c.dy - 32, c.dx - 1, c.dy - 20, c.dx - 6, c.dy - 12)
      ..cubicTo(c.dx - 12, c.dy - 4, c.dx - 23, c.dy - 3, c.dx - 28, c.dy + 4);
    final right = Path()
      ..moveTo(c.dx, c.dy + r)
      ..cubicTo(c.dx + 8, c.dy + r * .55, c.dx + 8, c.dy + 8, c.dx + 2, c.dy + 1)
      ..cubicTo(c.dx + 17, c.dy - 13, c.dx + 22, c.dy - 25, c.dx + 10, c.dy - 29)
      ..cubicTo(c.dx + 2, c.dy - 32, c.dx + 1, c.dy - 20, c.dx + 6, c.dy - 12)
      ..cubicTo(c.dx + 12, c.dy - 4, c.dx + 23, c.dy - 3, c.dx + 28, c.dy + 4);
    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);

    final center = Path()
      ..moveTo(c.dx, c.dy + r)
      ..cubicTo(c.dx - 9, c.dy + 20, c.dx - 9, c.dy + 8, c.dx, c.dy - 3)
      ..cubicTo(c.dx + 9, c.dy + 8, c.dx + 9, c.dy + 20, c.dx, c.dy + r);
    canvas.drawPath(center, thin);

    canvas.drawCircle(Offset(c.dx, c.dy + 5), 3.2, fill);
    _smallLeaf(canvas, Offset(c.dx - 24, c.dy + 6), 7, stroke, false);
    _smallLeaf(canvas, Offset(c.dx + 24, c.dy + 6), 7, stroke, true);
  }

  void _smallLeaf(Canvas canvas, Offset c, double r, Paint paint, bool flip) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..cubicTo(
        c.dx + (flip ? -r : r),
        c.dy - r * .45,
        c.dx + (flip ? -r : r),
        c.dy + r * .45,
        c.dx,
        c.dy + r,
      )
      ..cubicTo(
        c.dx + (flip ? r : -r),
        c.dy + r * .45,
        c.dx + (flip ? r : -r),
        c.dy - r * .45,
        c.dx,
        c.dy - r,
      );
    canvas.drawPath(p, paint);
  }

  void _eightPetalMedallion(
    Canvas canvas,
    Offset c,
    double r,
    Paint stroke,
    Paint thin,
    Paint fill,
  ) {
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final p = Offset(
        c.dx + math.cos(a) * r * .48,
        c.dy + math.sin(a) * r * .48,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p, width: r * .72, height: r * .38),
        stroke,
      );
    }
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      final p = Offset(
        c.dx + math.cos(a) * r * .34,
        c.dy + math.sin(a) * r * .34,
      );
      canvas.drawOval(
        Rect.fromCenter(center: p, width: r * .46, height: r * .22),
        thin,
      );
    }
    canvas.drawCircle(c, r * .22, fill);
    canvas.drawCircle(c, r * .62, stroke);
    _diamond(canvas, Offset(c.dx, c.dy - r * .72), 4.5, fill);
    _diamond(canvas, Offset(c.dx, c.dy + r * .72), 4.5, fill);
  }

  void _diamond(Canvas canvas, Offset center, double r, Paint paint) {
    final p = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicSplashOrnament oldDelegate) => oldDelegate.top != top;
}

/// زخارف جانبية رفيعة حول البسملة.
class BismillahFlourishPainter extends CustomPainter {
  const BismillahFlourishPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFE7AE4A);
    final p = Paint()
      ..color = gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;
    final y = size.height * .66;

    _flourish(canvas, 12, y, 1, p, fill);
    _flourish(canvas, size.width - 12, y, -1, p, fill);

    canvas.drawLine(const Offset(30, 60), const Offset(95, 60), p);
    canvas.drawLine(
      Offset(size.width - 30, 60),
      Offset(size.width - 95, 60),
      p,
    );
    _diamond(canvas, const Offset(101, 60), 4.5, fill);
    _diamond(canvas, Offset(size.width - 101, 60), 4.5, fill);
  }

  void _flourish(
    Canvas canvas,
    double x,
    double y,
    double dir,
    Paint p,
    Paint fill,
  ) {
    final path = Path()
      ..moveTo(x, y)
      ..cubicTo(
        x + 13 * dir,
        y - 2,
        x + 16 * dir,
        y - 13,
        x + 25 * dir,
        y - 12,
      )
      ..cubicTo(
        x + 34 * dir,
        y - 11,
        x + 32 * dir,
        y + 2,
        x + 23 * dir,
        y + 6,
      )
      ..cubicTo(
        x + 16 * dir,
        y + 9,
        x + 12 * dir,
        y + 3,
        x + 7 * dir,
        y,
      );
    canvas.drawPath(path, p);
    _diamond(canvas, Offset(x + 18 * dir, y - 2), 4.5, fill);
  }

  void _diamond(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BismillahFlourishPainter oldDelegate) => false;
}
