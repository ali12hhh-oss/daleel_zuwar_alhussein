import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../theme.dart';

// Note: Add flutter_compass to pubspec.yaml:
// dependencies:
//   flutter_compass: ^0.7.3
//   sensors_plus: ^4.0.2

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  bool _loading = true;
  String? _error;
  double? _qiblaDirection; // زاوية القبلة من الشمال
  double? _deviceHeading; // اتجاه الجهاز من الشمال
  Position? _position;
  bool _hasCompass = false;

  /// إحداثيات الكعبة المشرفة
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _getLocationAndCalculate();
    _initCompass();
  }

  Future<void> _initCompass() async {
    // Check if compass is available
    try {
      // flutter_compass availability check
      // CompassEvent? event = await FlutterCompass.events?.first;
      // if (event != null) {
      //   setState(() => _hasCompass = true);
      // }

      // For now, simulate compass availability
      // In real implementation, use flutter_compass
      setState(() => _hasCompass = true);
    } catch (e) {
      setState(() => _hasCompass = false);
    }
  }

  Future<void> _getLocationAndCalculate() async {
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

      final qibla = _calculateQiblaDirection(position.latitude, position.longitude);

      setState(() {
        _position = position;
        _qiblaDirection = qibla;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  /// ✅ حساب اتجاه القبلة رياضياً (معادلة spherical trigonometry)
  double _calculateQiblaDirection(double lat, double lng) {
    final latRad = lat * math.pi / 180.0;
    final lngRad = lng * math.pi / 180.0;
    final kaabaLatRad = kaabaLat * math.pi / 180.0;
    final kaabaLngRad = kaabaLng * math.pi / 180.0;

    final dLng = kaabaLngRad - lngRad;

    final y = math.sin(dLng);
    final x = math.cos(latRad) * math.tan(kaabaLatRad) - math.sin(latRad) * math.cos(dLng);

    var qibla = math.atan2(y, x) * 180.0 / math.pi;
    if (qibla < 0) qibla += 360.0;

    return qibla;
  }

  /// ✅ حساب زاوية القبلة بالنسبة للجهاز
  double _getQiblaAngle() {
    if (_qiblaDirection == null || _deviceHeading == null) return 0;
    var angle = _qiblaDirection! - _deviceHeading!;
    // Normalize to 0-360
    angle = angle % 360;
    if (angle < 0) angle += 360;
    return angle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اتجاه القبلة')),
      body: RefreshIndicator(
        onRefresh: _getLocationAndCalculate,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ✅ تعريف
            Card(
              color: AppColors.lightGold.withOpacity(0.3),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.explore, size: 48, color: AppColors.primaryGreen),
                    SizedBox(height: 12),
                    Text(
                      'اتجاه القبلة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'يتم حساب اتجاه القبلة تلقائياً حسب موقعك الجغرافي\n'
                      'حصراً على المذهب الشيعي الاثني عشري',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ حالة التحميل
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),

            // ✅ خطأ
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

            // ✅ البوصلة الاحترافية
            if (!_loading && _error == null && _qiblaDirection != null) ...[
              // ✅ الدائرة البوصلة الاحترافية
              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // الدائرة الخارجية (الإطار)
                      Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryGreen,
                            width: 4,
                          ),
                          gradient: RadialGradient(
                            colors: [
                              Colors.grey[50]!,
                              Colors.grey[200]!,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),

                      // الدائرة الداخلية
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.gold,
                            width: 2,
                          ),
                        ),
                      ),

                      // علامات الاتجاهات الرئيسية
                      ..._buildDirectionMarkers(),

                      // علامات الدرجات
                      ..._buildDegreeMarkers(),

                      // السهم الرئيسي (القبلة)
                      Transform.rotate(
                        angle: _getQiblaAngle() * math.pi / 180,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // مثلث القبلة
                            CustomPaint(
                              size: const Size(40, 50),
                              painter: _TrianglePainter(color: AppColors.primaryGreen),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'القبلة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // مؤشر الشمال
                      Transform.rotate(
                        angle: -(_deviceHeading ?? 0) * math.pi / 180,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.9),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              'N',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // المركز
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ✅ معلومات القبلة
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _InfoBox(
                            label: 'زاوية القبلة',
                            value: '${_qiblaDirection!.toStringAsFixed(1)}°',
                            color: AppColors.primaryGreen,
                          ),
                          _InfoBox(
                            label: 'اتجاه الجهاز',
                            value: '${(_deviceHeading ?? 0).toStringAsFixed(1)}°',
                            color: Colors.blue,
                          ),
                          _InfoBox(
                            label: 'الفرق',
                            value: '${_getQiblaAngle().toStringAsFixed(1)}°',
                            color: AppColors.gold,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ✅ الموقع
              if (_position != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'موقعك الحالي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_position!.latitude.toStringAsFixed(4)}°N, ${_position!.longitude.toStringAsFixed(4)}°E',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ✅ ملاحظات
              Card(
                color: Colors.grey[100],
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'كيفية الاستخدام:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• حرك الجهاز حتى يتجه السهم الأخضر نحو القبلة\n'
                        '• وقف بعيداً عن الأجسام المعدنية\n'
                        '• حافظ على الجهاز أفقياً\n'
                        '• الزاوية محسوبة من الشمال نحو الشرق\n'
                        '• حصراً على المذهب الشيعي الاثني عشري',
                        style: TextStyle(fontSize: 12, height: 1.8),
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

  /// ✅ علامات الاتجاهات الرئيسية
  List<Widget> _buildDirectionMarkers() {
    final directions = [
      {'label': 'شمال', 'angle': 0, 'color': Colors.red},
      {'label': 'شرق', 'angle': 90, 'color': Colors.grey[700]},
      {'label': 'جنوب', 'angle': 180, 'color': Colors.grey[700]},
      {'label': 'غرب', 'angle': 270, 'color': Colors.grey[700]},
    ];

    return directions.map((d) {
      final angle = (d['angle'] as num) * math.pi / 180;
      final x = 140 * math.sin(angle);
      final y = -140 * math.cos(angle);

      return Positioned(
        left: 160 + x - 20,
        top: 160 + y - 10,
        child: Text(
          d['label'] as String,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: d['color'] as Color?,
          ),
        ),
      );
    }).toList();
  }

  /// ✅ علامات الدرجات
  List<Widget> _buildDegreeMarkers() {
    List<Widget> markers = [];
    for (int i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180;
      final x1 = 130 * math.sin(angle);
      final y1 = -130 * math.cos(angle);
      final x2 = 140 * math.sin(angle);
      final y2 = -140 * math.cos(angle);

      markers.add(
        Positioned(
          left: 160 + x1 - 1,
          top: 160 + y1 - 1,
          child: Container(
            width: 2,
            height: 2,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }
    return markers;
  }
}

/// ✅ رسم مثلث القبلة
class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ✅ صندوق معلومات
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
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
