
# Rewrite qibla_screen.dart with clean code, no escape issues
qibla_clean = r'''import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  double? _qiblaDirection;
  double _deviceHeading = 0;
  double _smoothHeading = 0;
  Position? _position;
  bool _hasCompass = false;
  bool _usingGpsFallback = false;

  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  AnimationController? _animationController;

  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _getLocationAndCalculate();
    _initCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _initCompass() async {
    try {
      final compassEvents = FlutterCompass.events;
      if (compassEvents != null) {
        _compassSubscription = compassEvents.listen((event) {
          if (mounted && event.heading != null) {
            setState(() {
              _hasCompass = true;
              _usingGpsFallback = false;
              _smoothHeading = _lerpAngle(_smoothHeading, event.heading!, 0.15);
              _deviceHeading = _smoothHeading;
            });
          }
        });
      }
    } catch (e) {
      _tryMagnetometerFallback();
    }
  }

  void _tryMagnetometerFallback() {
    try {
      _magnetometerSubscription = magnetometerEvents.listen((event) {
        if (mounted) {
          final heading = math.atan2(event.y, event.x) * 180 / math.pi;
          final normalizedHeading = (heading < 0) ? heading + 360 : heading;
          setState(() {
            _hasCompass = true;
            _usingGpsFallback = false;
            _smoothHeading = _lerpAngle(_smoothHeading, normalizedHeading, 0.15);
            _deviceHeading = _smoothHeading;
          });
        }
      });
    } catch (e) {
      setState(() {
        _hasCompass = false;
        _usingGpsFallback = true;
      });
    }
  }

  double _lerpAngle(double current, double target, double factor) {
    var diff = target - current;
    while (diff < -180) diff += 360;
    while (diff > 180) diff -= 360;
    return current + diff * factor;
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

  double _calculateQiblaDirection(double lat, double lng) {
    final latRad = lat * math.pi / 180.0;
    final lngRad = lng * math.pi / 180.0;
    final kaabaLatRad = kaabaLat * math.pi / 180.0;
    final kaabaLngRad = kaabaLng * math.pi / 180.0;

    final dLng = kaabaLngRad - lngRad;

    final y = math.sin(dLng);
    final x = math.cos(latRad) * math.tan(kaabaLatRad) -
        math.sin(latRad) * math.cos(dLng);

    var qibla = math.atan2(y, x) * 180.0 / math.pi;
    if (qibla < 0) qibla += 360.0;

    return qibla;
  }

  double _getQiblaAngle() {
    if (_qiblaDirection == null) return 0;
    var angle = _qiblaDirection! - _deviceHeading;
    angle = angle % 360;
    if (angle < 0) angle += 360;
    return angle;
  }

  double _getAngleDifference() {
    if (_qiblaDirection == null) return 0;
    var diff = _qiblaDirection! - _deviceHeading;
    while (diff < -180) diff += 360;
    while (diff > 180) diff -= 360;
    return diff.abs();
  }

  bool _isFacingQibla() {
    return _getAngleDifference() < 5;
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
                      'حرك جهازك لتحديد اتجاه القبلة\n'
                      'حصراً على المذهب الشيعي الاثني عشري',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
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

            if (!_loading && _error == null && _qiblaDirection != null) ...[
              if (_isFacingQibla())
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'أنت متجه نحو القبلة',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

              Center(
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
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

                      Transform.rotate(
                        angle: -_deviceHeading * math.pi / 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ..._buildDirectionMarkers(),
                            ..._buildDegreeMarkers(),
                          ],
                        ),
                      ),

                      Transform.rotate(
                        angle: _getQiblaAngle() * math.pi / 180,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),

                      Positioned(
                        top: 20,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withOpacity(0.9),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'N',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),

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
                            value: '${_deviceHeading.toStringAsFixed(1)}°',
                            color: Colors.blue,
                          ),
                          _InfoBox(
                            label: 'الفرق',
                            value: '${_getAngleDifference().toStringAsFixed(1)}°',
                            color: _isFacingQibla() ? Colors.green : AppColors.gold,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

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
                        '• عندما يصبح الفرق أقل من 5 درجات، ستظهر رسالة التأكيد\n'
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

  List<Widget> _buildDirectionMarkers() {
    final directions = [
      {'label': 'شمال', 'angle': 0, 'color': Colors.red},
      {'label': 'شرق', 'angle': 90, 'color': Colors.grey[700]},
      {'label': 'جنوب', 'angle': 180, 'color': Colors.grey[700]},
      {'label': 'غرب', 'angle': 270, 'color': Colors.grey[700]},
    ];

    return directions.map((d) {
      final angle = (d['angle'] as num) * math.pi / 180;
      final x = 120 * math.sin(angle);
      final y = -120 * math.cos(angle);

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

  List<Widget> _buildDegreeMarkers() {
    List<Widget> markers = [];
    for (int i = 0; i < 360; i += 30) {
      final angle = i * math.pi / 180;
      final x1 = 130 * math.sin(angle);
      final y1 = -130 * math.cos(angle);

      markers.add(
        Positioned(
          left: 160 + x1 - 1,
          top: 160 + y1 - 1,
          child: Container(
            width: i % 90 == 0 ? 4 : 2,
            height: i % 90 == 0 ? 4 : 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i % 90 == 0 ? Colors.black : Colors.grey,
            ),
          ),
        ),
      );
    }
    return markers;
  }
}

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

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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
'''

# Save to output directory
output_path = '/mnt/agents/output/qibla_screen.dart'
with open(output_path, 'w', encoding='utf-8') as f:
    f.write(qibla_clean)

print(f"✅ qibla_screen.dart saved: {len(qibla_clean)} chars")
print(f"📁 Path: {output_path}")
