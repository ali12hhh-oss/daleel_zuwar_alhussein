import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  bool _loading = true;
  String? _error;
  double? _qiblaDirection; // زاوية القبلة من الشمال
  Position? _position;

  /// إحداثيات الكعبة المشرفة
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  @override
  void initState() {
    super.initState();
    _getLocationAndCalculate();
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
                      'استخدم البوصلة للتوجه نحو الكعبة المشرفة',
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

            // ✅ البوصلة
            if (!_loading && _error == null && _qiblaDirection != null) ...[
              // ✅ الدائرة البوصلة
              Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // الدائرة الخارجية
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryGreen,
                            width: 3,
                          ),
                          color: Colors.grey[100],
                        ),
                      ),
                      // علامات الاتجاهات
                      ..._buildDirectionMarkers(),
                      // السهم
                      Transform.rotate(
                        angle: _qiblaDirection! * math.pi / 180,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              color: AppColors.primaryGreen,
                              size: 60,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'القبلة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // المركز
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ✅ الزاوية
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'زاوية القبلة',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_qiblaDirection!.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'من الشمال باتجاه الشرق',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
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
                        '• وقف بعيداً عن الأجسام المعدنية\n'
                        '• حافظ على الجهاز أفقياً\n'
                        '• استخدم السهم الأخضر للتوجه نحو القبلة\n'
                        '• الزاوية محسوبة من الشمال نحو الشرق',
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

  /// ✅ علامات الاتجاهات على الدائرة
  List<Widget> _buildDirectionMarkers() {
    final directions = [
      {'label': 'ش', 'angle': 0},     // شمال
      {'label': 'ج', 'angle': 90},    // شرق
      {'label': 'جب', 'angle': 135},  // جنوب شرق (تقريبي للقبلة من العراق)
      {'label': 'ج', 'angle': 180},   // جنوب
      {'label': 'غ', 'angle': 270},   // غرب
    ];

    return directions.map((d) {
      final angle = (d['angle'] as num) * math.pi / 180;
      final x = 130 * math.sin(angle);
      final y = -130 * math.cos(angle);

      return Positioned(
        left: 140 + x - 10,
        top: 140 + y - 10,
        child: Text(
          d['label'] as String,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: d['label'] == 'جب' ? AppColors.gold : Colors.grey[600],
          ),
        ),
      );
    }).toList();
  }
}
