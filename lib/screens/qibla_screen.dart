import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geomag/geomag.dart';
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
  double _magneticDeclination = 0.0;
  Position? _position;

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
      _magnetometerSubscription = magnetometerEventStream().listen((event) {
        if (mounted) {
          final heading = math.atan2(event.y, event.x) * 180 / math.pi;
          final normalizedHeading = (heading < 0) ? heading + 360 : heading;
          setState(() {
            _smoothHeading = _lerpAngle(_smoothHeading, normalizedHeading, 0.15);
            _deviceHeading = _smoothHeading;
          });
        }
      });
    } catch (e) {
      // Magnetometer not available
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
      final declination = _calculateDeclination(position.latitude, position.longitude);

      setState(() {
        _position = position;
        _qiblaDirection = qibla;
        _magneticDeclination = declination;
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

  /// يحسب الانحراف المغناطيسي (الفرق بين الشمال المغناطيسي والشمال الحقيقي)
  /// لموقع معيّن باستخدام نموذج WMM. يُرجع 0.0 في حال فشل الحساب بدل تعطيل التطبيق.
  double _calculateDeclination(double lat, double lng) {
    try {
      final geoMag = GeoMag();
      final result = geoMag.calculate(lat, lng, 0, DateTime.now());
      return result.dec;
    } catch (e) {
      return 0.0;
    }
  }

  /// الاتجاه الحقيقي (بالنسبة للشمال الجغرافي) بعد تصحيح قراءة البوصلة
  /// المغناطيسية بإضافة الانحراف المغناطيسي المحسوب لموقع المستخدم.
  ///
  /// هذا هو المرجع الوحيد المستخدم في كل حسابات وعرض الاتجاهات بالشاشة
  /// (قرص البوصلة وسهم القبلة معاً)، لضمان عدم وجود أي تعارض بينهما.
  double get _trueHeading {
    final t = _deviceHeading + _magneticDeclination;
    return (t + 360) % 360;
  }

  double _getQiblaAngle() {
    if (_qiblaDirection == null) return 0;
    var angle = _qiblaDirection! - _trueHeading;
    angle = angle % 360;
    if (angle < 0) angle += 360;
    return angle;
  }

  double _getAngleDifference() {
    if (_qiblaDirection == null) return 0;
    var diff = _qiblaDirection! - _trueHeading;
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
                      'حرك جهازك لتحديد اتجاه القبلة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
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

                      // قرص البوصلة (الاتجاهات والدرجات) يدور بمرجع
                      // _trueHeading نفسه المستخدم لسهم القبلة، لضمان
                      // توافق الاتجاهات المعروضة مع اتجاه القبلة الفعلي
                      // ومنع أي تعارض بينهما.
                      Transform.rotate(
                        angle: -_trueHeading * math.pi / 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ..._buildDirectionMarkers(),
                            ..._buildDegreeMarkers(),
                          ],
                        ),
                      ),

                      // مجسّم الكعبة المشرفة يشير دوماً لاتجاه القبلة
                      // الصحيح، ويدور حسب حركة الجهاز.
                      Transform.rotate(
                        angle: _getQiblaAngle() * math.pi / 180,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _KaabaIcon(size: 46),
                            const SizedBox(height: 6),
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
                            const SizedBox(height: 70),
                          ],
                        ),
                      ),

                      // مؤشر ثابت لاتجاه مقدمة الجهاز (وليس للشمال، تجنباً
                      // لأي التباس مع كلمة "شمال" الفعلية بالقرص الدوّار).
                      Positioned(
                        top: 6,
                        child: Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(2),
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
                            value: '${_trueHeading.toStringAsFixed(1)}°',
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
                        const SizedBox(height: 4),
                        Text(
                          'الانحراف المغناطيسي: ${_magneticDeclination.toStringAsFixed(2)}°',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                        '• حرك الجهاز حتى يتجه مجسم الكعبة نحو الأعلى',
                        style: TextStyle(fontSize: 12, height: 1.8),
                      ),
                      Text(
                        '• عندما يصبح الفرق أقل من 5 درجات، ستظهر رسالة التأكيد',
                        style: TextStyle(fontSize: 12, height: 1.8),
                      ),
                      Text(
                        '• وقف بعيداً عن الأجسام المعدنية',
                        style: TextStyle(fontSize: 12, height: 1.8),
                      ),
                      Text(
                        '• حافظ على الجهاز أفقياً',
                        style: TextStyle(fontSize: 12, height: 1.8),
                      ),
                      Text(
                        '• الزاوية محسوبة من الشمال نحو الشرق',
                        style: TextStyle(fontSize: 12, height: 1.8),
                      ),
                      Text(
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

/// مجسّم مبسّط للكعبة المشرّفة بشكل ثلاثي الأبعاد (مكعب أسود بكسوة
/// وحزام ذهبي)، يُستخدم كمؤشر لاتجاه القبلة بدل السهم المثلث السابق.
class _KaabaIcon extends StatelessWidget {
  final double size;
  const _KaabaIcon({this.size = 46});

  @override
  Widget build(BuildContext context) {
    final depth = size * 0.32;

    return SizedBox(
      width: size + depth,
      height: size + depth,
      child: Stack(
        children: [
          // الوجه الجانبي (يعطي إحساس العمق/الثلاثية الأبعاد)
          Positioned(
            right: 0,
            top: depth * 0.5,
            child: Transform(
              alignment: Alignment.topLeft,
              transform: Matrix4.skewY(-0.55),
              child: Container(
                width: depth,
                height: size,
                decoration: const BoxDecoration(
                  color: Color(0xFF060606),
                ),
              ),
            ),
          ),
          // السطح العلوي (يعطي إحساس العمق من الأعلى)
          Positioned(
            left: depth * 0.5,
            top: 0,
            child: Transform(
              alignment: Alignment.bottomLeft,
              transform: Matrix4.skewX(-0.55),
              child: Container(
                width: size,
                height: depth,
                decoration: const BoxDecoration(
                  color: Color(0xFF1C1C1C),
                ),
              ),
            ),
          ),
          // الواجهة الأمامية: الكسوة السوداء + الحزام الذهبي (الحزام
          // المطرّز بالآيات القرآنية أعلى الكعبة تقليدياً)
          Positioned(
            left: 0,
            top: depth,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0B),
                border: Border.all(color: Colors.black, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 6,
                    offset: const Offset(1, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: size * 0.28),
                  Container(
                    width: size,
                    height: size * 0.2,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFD4AF37),
                          Color(0xFFF4E5A1),
                          Color(0xFFD4AF37),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: size * 0.55,
                        height: 1.4,
                        color: Colors.black26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // الباب الذهبي الصغير أسفل الواجهة (باب الكعبة)
          Positioned(
            left: size * 0.62,
            top: depth + size * 0.62,
            child: Container(
              width: size * 0.16,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: const Color(0xFFC9A227),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
