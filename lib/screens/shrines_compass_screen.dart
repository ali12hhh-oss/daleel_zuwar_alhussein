import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geomag/geomag.dart';
import '../theme.dart';

/// نقطة مقدّسة يمكن تحديد اتجاهها (مرقد شريف أو مسجد أو مقام)
class SacredPlace {
  final String name;
  final String subtitle;
  final double lat;
  final double lng;

  const SacredPlace({
    required this.name,
    required this.subtitle,
    required this.lat,
    required this.lng,
  });
}

/// قائمة المراقد الشريفة والأماكن المقدسة (إحداثيات دقيقة لكل موقع)
const List<SacredPlace> sacredPlaces = [
  SacredPlace(
    name: 'المسجد النبوي الشريف',
    subtitle: 'قبر الرسول محمد ﷺ - المدينة المنورة',
    lat: 24.4672,
    lng: 39.6111,
  ),
  SacredPlace(
    name: 'البقيع الشريف',
    subtitle:
        'الإمام الحسن، الإمام زين العابدين، الإمام الباقر، الإمام الصادق (ع) - المدينة المنورة',
    lat: 24.4669,
    lng: 39.6164,
  ),
  SacredPlace(
    name: 'مرقد الإمام علي (ع)',
    subtitle: 'النجف الأشرف',
    lat: 31.9959,
    lng: 44.3146,
  ),
  SacredPlace(
    name: 'مرقد الإمام الحسين (ع)',
    subtitle: 'كربلاء المقدسة',
    lat: 32.6164,
    lng: 44.0323,
  ),
  SacredPlace(
    name: 'مرقد الإمامين الكاظم والجواد (ع)',
    subtitle: 'الكاظمية - بغداد',
    lat: 33.3800,
    lng: 44.3381,
  ),
  SacredPlace(
    name: 'مرقد الإمامين الهادي والعسكري (ع)',
    subtitle: 'سامراء',
    lat: 34.1989,
    lng: 43.8735,
  ),
  SacredPlace(
    name: 'مرقد الإمام الرضا (ع)',
    subtitle: 'مشهد المقدسة',
    lat: 36.2880,
    lng: 59.6157,
  ),
  SacredPlace(
    name: 'سرداب الغيبة (مقام الإمام المهدي عج)',
    subtitle: 'سامراء',
    lat: 34.1989,
    lng: 43.8735,
  ),
];

class ShrinesCompassScreen extends StatefulWidget {
  const ShrinesCompassScreen({super.key});

  @override
  State<ShrinesCompassScreen> createState() => _ShrinesCompassScreenState();
}

class _ShrinesCompassScreenState extends State<ShrinesCompassScreen> {
  bool _loading = true;
  String? _error;
  double? _targetDirection;
  double _deviceHeading = 0;
  double _smoothHeading = 0;
  Position? _position;
  double _declination = 0;

  SacredPlace _selectedPlace = sacredPlaces.first;

  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  @override
  void initState() {
    super.initState();
    _getLocationAndCalculate();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initCompass() async {
    try {
      final compassEvents = FlutterCompass.events;
      if (compassEvents != null) {
        _compassSubscription = compassEvents.listen((event) {
          if (mounted && event.heading != null) {
            final trueHeading = _toTrueHeading(event.heading!);
            setState(() {
              _smoothHeading = _lerpAngle(_smoothHeading, trueHeading, 0.15);
              _deviceHeading = _smoothHeading;
            });
          }
        });
      } else {
        _tryMagnetometerFallback();
      }
    } catch (e) {
      _tryMagnetometerFallback();
    }
  }

  void _tryMagnetometerFallback() {
    try {
      _magnetometerSubscription = magnetometerEventStream().listen((event) {
        if (mounted) {
          final heading = math.atan2(event.y, event.x) * 180 / math.pi;
          final normalizedHeading = (heading < 0) ? heading + 360 : heading;
          final trueHeading = _toTrueHeading(normalizedHeading);
          setState(() {
            _smoothHeading = _lerpAngle(_smoothHeading, trueHeading, 0.15);
            _deviceHeading = _smoothHeading;
          });
        }
      });
    } catch (e) {
      // Magnetometer not available
    }
  }

  /// يحوّل اتجاهاً مقروءاً من البوصلة (نسبة للشمال المغناطيسي) إلى اتجاه
  /// حقيقي (نسبة للشمال الجغرافي)، باستخدام الانحراف المغناطيسي المحسوب
  /// لموقع المستخدم الحالي.
  double _toTrueHeading(double magneticHeading) {
    var trueHeading = magneticHeading + _declination;
    trueHeading = trueHeading % 360;
    if (trueHeading < 0) trueHeading += 360;
    return trueHeading;
  }

  double _lerpAngle(double current, double target, double factor) {
    var diff = target - current;
    while (diff < -180) diff += 360;
    while (diff > 180) diff -= 360;
    return current + diff * factor;
  }

  Future<void> _getLocationAndCalculate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('يرجى تفعيل خدمة الموقع (GPS)');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض إذن الموقع');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('إذن الموقع مرفوض دائماً');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double declination = 0;
      try {
        final geoMag = GeoMag();
        final geoMagResult = geoMag.calculate(
          position.latitude,
          position.longitude,
          position.altitude,
        );
        declination = geoMagResult.dec;
      } catch (_) {
        declination = 0; // في حال فشل الحساب، نكمل بدون تصحيح بدل تعطيل الشاشة
      }

      setState(() {
        _position = position;
        _declination = declination;
        _targetDirection = _calculateBearing(
          position.latitude,
          position.longitude,
          _selectedPlace.lat,
          _selectedPlace.lng,
        );
        _loading = false;
      });

      _compassSubscription?.cancel();
      _magnetometerSubscription?.cancel();
      _initCompass();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// حساب زاوية الاتجاه (bearing) بالدائرة العظمى بين نقطتين على الكرة
  /// الأرضية، بالنسبة للشمال الجغرافي الحقيقي.
  double _calculateBearing(
      double fromLat, double fromLng, double toLat, double toLng) {
    final fromLatRad = fromLat * math.pi / 180.0;
    final fromLngRad = fromLng * math.pi / 180.0;
    final toLatRad = toLat * math.pi / 180.0;
    final toLngRad = toLng * math.pi / 180.0;

    final dLng = toLngRad - fromLngRad;

    final y = math.sin(dLng);
    final x = math.cos(fromLatRad) * math.tan(toLatRad) -
        math.sin(fromLatRad) * math.cos(dLng);

    var bearing = math.atan2(y, x) * 180.0 / math.pi;
    if (bearing < 0) bearing += 360.0;

    return bearing;
  }

  void _onPlaceSelected(SacredPlace place) {
    setState(() {
      _selectedPlace = place;
      if (_position != null) {
        _targetDirection = _calculateBearing(
          _position!.latitude,
          _position!.longitude,
          place.lat,
          place.lng,
        );
      }
    });
  }

  double _getArrowAngle() {
    if (_targetDirection == null) return 0;
    var angle = _targetDirection! - _deviceHeading;
    angle = angle % 360;
    if (angle < 0) angle += 360;
    return angle;
  }

  double _getAngleDifference() {
    if (_targetDirection == null) return 0;
    var diff = _targetDirection! - _deviceHeading;
    while (diff < -180) diff += 360;
    while (diff > 180) diff -= 360;
    return diff.abs();
  }

  bool _isFacingTarget() => _getAngleDifference() < 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EC),
      appBar: AppBar(title: const Text('اتجاه المراقد الشريفة')),
      body: RefreshIndicator(
        onRefresh: _getLocationAndCalculate,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // قائمة اختيار المرقد/المكان المقدس
            Card(
              elevation: 2,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اختر المكان المقدس',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<SacredPlace>(
                      initialValue: _selectedPlace,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      items: sacredPlaces.map((place) {
                        return DropdownMenuItem<SacredPlace>(
                          value: place,
                          child: Text(
                            place.name,
                            textDirection: TextDirection.rtl,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (place) {
                        if (place != null) _onPlaceSelected(place);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedPlace.subtitle,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (_error != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _getLocationAndCalculate,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),

            if (!_loading && _error == null && _targetDirection != null) ...[
              if (_isFacingTarget())
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'أنت متجه نحو ${_selectedPlace.name}',
                          textDirection: TextDirection.rtl,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // البوصلة المجسّمة الاحترافية
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: CustomPaint(
                    painter: _CompassDialPainter(
                      headingDeg: _deviceHeading,
                    ),
                    foregroundPainter: _CompassNeedlePainter(
                      pointerAngleDeg: _getArrowAngle(),
                      isAligned: _isFacingTarget(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _selectedPlace.name,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _InfoBox(
                        label: 'زاوية الاتجاه',
                        value: '${_targetDirection!.toStringAsFixed(1)}°',
                        color: AppColors.primaryGreen,
                      ),
                      _InfoBox(
                        label: 'اتجاه الجهاز',
                        value: '${_deviceHeading.toStringAsFixed(1)}°',
                        color: Colors.blue,
                      ),
                      _InfoBox(
                        label: 'الفرق',
                        value: '${_getAngleDifference().toStringAsFixed(1)}°',
                        color:
                            _isFacingTarget() ? Colors.green : AppColors.gold,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// يرسم قرص البوصلة المعدني: الإطار الخارجي المتدرج، حلقة التدريج
/// بالدرجات، والحروف الأساسية (شمال/شرق/جنوب/غرب)، ويدور بالكامل
/// مع اتجاه الجهاز حتى يبقى الشمال يشير دائماً للاتجاه الحقيقي.
class _CompassDialPainter extends CustomPainter {
  final double headingDeg;

  _CompassDialPainter({required this.headingDeg});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // === الإطار المعدني الخارجي ===
    final bezelGradient = RadialGradient(
      colors: [
        const Color(0xFFFFF6D8),
        AppColors.gold.withOpacity(0.9),
        const Color(0xFF8A6A1E),
      ],
      stops: const [0.75, 0.92, 1.0],
    );
    final bezelPaint = Paint()
      ..shader = bezelGradient
          .createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bezelPaint);

    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius - 2)),
      Colors.black,
      8,
      true,
    );

    // === وجه البوصلة الزجاجي الداخلي ===
    final faceRadius = radius - 14;
    final facePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [Colors.white, const Color(0xFFE9E6DD)],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: faceRadius));
    canvas.drawCircle(center, faceRadius, facePaint);

    canvas.drawCircle(
      center,
      faceRadius,
      Paint()
        ..color = AppColors.primaryGreen.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // === حلقة التدريج والحروف (تدور مع اتجاه الجهاز) ===
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-headingDeg * math.pi / 180);

    final tickRadius = faceRadius - 8;
    for (int deg = 0; deg < 360; deg += 6) {
      final isMajor = deg % 30 == 0;
      final isCardinal = deg % 90 == 0;
      final tickLength = isCardinal ? 16.0 : (isMajor ? 11.0 : 5.0);
      final tickColor = isCardinal
          ? (deg == 0 ? Colors.red[700]! : Colors.grey[850]!)
          : Colors.grey[500]!;

      final angle = deg * math.pi / 180;
      final outer = Offset(
        tickRadius * math.sin(angle),
        -tickRadius * math.cos(angle),
      );
      final inner = Offset(
        (tickRadius - tickLength) * math.sin(angle),
        -(tickRadius - tickLength) * math.cos(angle),
      );

      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = tickColor
          ..strokeWidth = isCardinal ? 2.2 : (isMajor ? 1.6 : 1.0)
          ..strokeCap = StrokeCap.round,
      );
    }

    // حروف الاتجاهات الأساسية
    const labels = {0: 'شمال', 90: 'شرق', 180: 'جنوب', 270: 'غرب'};
    labels.forEach((deg, label) {
      final angle = deg * math.pi / 180;
      final labelRadius = tickRadius - 30;
      final pos = Offset(
        labelRadius * math.sin(angle),
        -labelRadius * math.cos(angle),
      );

      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: deg == 0 ? Colors.red[700] : Colors.grey[850],
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.rtl,
      )..layout();

      // إبقاء النص معتدلاً (غير مقلوب) مهما دار القرص
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(headingDeg * math.pi / 180);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    });

    canvas.restore();

    // === مؤشر ثابت أعلى الجهاز (يمثل مقدمة الهاتف) ===
    final topIndicatorPath = Path()
      ..moveTo(center.dx, center.dy - radius + 4)
      ..lineTo(center.dx - 7, center.dy - radius + 18)
      ..lineTo(center.dx + 7, center.dy - radius + 18)
      ..close();
    canvas.drawPath(
      topIndicatorPath,
      Paint()..color = Colors.red[700]!,
    );
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) =>
      oldDelegate.headingDeg != headingDeg;
}

/// يرسم إبرة البوصلة المجسّمة التي تشير نحو المرقد المختار، بتدرج لوني
/// وظل يعطيها منظوراً ثلاثي الأبعاد، بالإضافة لمحور مركزي لامع.
class _CompassNeedlePainter extends CustomPainter {
  final double pointerAngleDeg;
  final bool isAligned;

  _CompassNeedlePainter({
    required this.pointerAngleDeg,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final needleColor = isAligned ? Colors.green[700]! : AppColors.primaryGreen;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pointerAngleDeg * math.pi / 180);

    final needleLength = size.width * 0.34;
    final tailLength = size.width * 0.14;

    // ظل الإبرة (لإيحاء العمق)
    final shadowPath = Path()
      ..moveTo(3, -needleLength + 3)
      ..lineTo(11, 6)
      ..lineTo(-9, 6)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // الجزء الأمامي من الإبرة (يشير للمرقد) بتدرج لوني
    final frontPath = Path()
      ..moveTo(0, -needleLength)
      ..lineTo(9, 4)
      ..lineTo(-9, 4)
      ..close();
    final frontGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [needleColor.withOpacity(0.95), needleColor.withOpacity(0.65)],
    );
    canvas.drawPath(
      frontPath,
      Paint()
        ..shader = frontGradient.createShader(
          Rect.fromLTWH(-9, -needleLength, 18, needleLength + 4),
        ),
    );
    canvas.drawPath(
      frontPath,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // الذيل الخلفي (بلون ذهبي هادئ للتوازن البصري)
    final tailPath = Path()
      ..moveTo(0, tailLength)
      ..lineTo(6, 4)
      ..lineTo(-6, 4)
      ..close();
    canvas.drawPath(
      tailPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gold.withOpacity(0.9),
            AppColors.gold.withOpacity(0.4)
          ],
        ).createShader(Rect.fromLTWH(-6, 4, 12, tailLength)),
    );

    canvas.restore();

    // === المحور المركزي اللامع ===
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [Colors.white, Colors.grey[400]!, Colors.grey[700]!],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: 12)),
    );
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(center.dx - 3, center.dy - 3),
      3,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassNeedlePainter oldDelegate) =>
      oldDelegate.pointerAngleDeg != pointerAngleDeg ||
      oldDelegate.isAligned != isAligned;
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
