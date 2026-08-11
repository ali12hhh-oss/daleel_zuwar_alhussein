import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geomag/geomag.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // الموقع الجغرافي للكعبة
  // ============================================================

  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  // ============================================================
  // الحالة
  // ============================================================

  bool _loading = true;
  String? _error;

  Position? _position;

  double? _qiblaDirection;

  double _deviceHeading = 0;
  double _smoothHeading = 0;

  double _magneticDeclination = 0;

  double? _headingAccuracy;

  bool _usingFallbackCompass = false;
  bool _compassAvailable = false;

  // لتثبيت رسالة "أنت متجه نحو القبلة"
  int _qiblaMatchCounter = 0;

  // ============================================================
  // Sensor subscriptions
  // ============================================================

  StreamSubscription<CompassEvent>? _compassSubscription;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  // ============================================================
  // آخر قراءات المستشعرات
  // ============================================================

  AccelerometerEvent? _lastAccelerometer;
  MagnetometerEvent? _lastMagnetometer;

  // ============================================================
  // Animation
  // ============================================================

  AnimationController? _animationController;

  // ============================================================
  // Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _getLocationAndCalculate();
    _initCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _animationController?.dispose();

    super.dispose();
  }

  // ============================================================
  // البوصلة الأساسية
  // ============================================================

  Future<void> _initCompass() async {
    try {
      final events = FlutterCompass.events;

      if (events == null) {
        _startSensorFallback();
        return;
      }

      _compassSubscription = events.listen(
        (event) {
          if (!mounted) return;

          final heading = event.heading;

          if (heading == null || heading.isNaN) {
            return;
          }

          _compassAvailable = true;
          _usingFallbackCompass = false;

          _headingAccuracy = event.accuracy;

          _updateHeading(heading);
        },
        onError: (_) {
          _startSensorFallback();
        },
      );
    } catch (_) {
      _startSensorFallback();
    }
  }

  // ============================================================
  // Fallback
  //
  // نستخدم Accelerometer + Magnetometer مع تصحيح الميل.
  // هذا أفضل بكثير من:
  //
  // atan2(magnetometer.y, magnetometer.x)
  //
  // لأن ذلك الحساب يفشل عندما يميل الهاتف.
  // ============================================================

  void _startSensorFallback() {
    if (_usingFallbackCompass) return;

    _usingFallbackCompass = true;

    try {
      _accelerometerSubscription =
          accelerometerEventStream().listen((event) {
        _lastAccelerometer = event;
        _calculateFallbackHeading();
      });

      _magnetometerSubscription =
          magnetometerEventStream().listen((event) {
        _lastMagnetometer = event;
        _calculateFallbackHeading();
      });
    } catch (_) {
      _compassAvailable = false;
    }
  }

  void _calculateFallbackHeading() {
    if (!mounted) return;

    final acc = _lastAccelerometer;
    final mag = _lastMagnetometer;

    if (acc == null || mag == null) return;

    try {
      // ----------------------------------------------------------
      // متجه الجاذبية
      // ----------------------------------------------------------

      double gx = acc.x;
      double gy = acc.y;
      double gz = acc.z;

      final gLength = math.sqrt(
        gx * gx + gy * gy + gz * gz,
      );

      if (gLength < 0.1) return;

      gx /= gLength;
      gy /= gLength;
      gz /= gLength;

      // ----------------------------------------------------------
      // متجه المجال المغناطيسي
      // ----------------------------------------------------------

      double mx = mag.x;
      double my = mag.y;
      double mz = mag.z;

      final mLength = math.sqrt(
        mx * mx + my * my + mz * mz,
      );

      if (mLength < 0.1) return;

      mx /= mLength;
      my /= mLength;
      mz /= mLength;

      // ----------------------------------------------------------
      // East = Magnetic × Gravity
      // ----------------------------------------------------------

      double ex = my * gz - mz * gy;
      double ey = mz * gx - mx * gz;
      double ez = mx * gy - my * gx;

      final eLength = math.sqrt(
        ex * ex + ey * ey + ez * ez,
      );

      if (eLength < 0.01) return;

      ex /= eLength;
      ey /= eLength;
      ez /= eLength;

      // ----------------------------------------------------------
      // North = Gravity × East
      // ----------------------------------------------------------

      final nx = gy * ez - gz * ey;
      final ny = gz * ex - gx * ez;
      final nz = gx * ey - gy * ex;

      // ----------------------------------------------------------
      // حساب الاتجاه
      // ----------------------------------------------------------

      var heading =
          math.atan2(ex, nx) * 180 / math.pi;

      if (heading < 0) {
        heading += 360;
      }

      _compassAvailable = true;

      _updateHeading(heading);
    } catch (_) {
      // تجاهل القراءة التالفة
    }
  }

  // ============================================================
  // تحديث الاتجاه مع smoothing
  // ============================================================

  void _updateHeading(double heading) {
    if (heading.isNaN || heading.isInfinite) return;

    heading = (heading + 360) % 360;

    // أول قراءة
    if (_smoothHeading == 0 && _deviceHeading == 0) {
      _smoothHeading = heading;
    } else {
      _smoothHeading = _lerpAngle(
        _smoothHeading,
        heading,
        0.18,
      );
    }

    _deviceHeading = _smoothHeading;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // Smooth angle
  // ============================================================

  double _lerpAngle(
    double current,
    double target,
    double factor,
  ) {
    var difference = target - current;

    while (difference < -180) {
      difference += 360;
    }

    while (difference > 180) {
      difference -= 360;
    }

    return (current + difference * factor + 360) % 360;
  }

  // ============================================================
  // الموقع + حساب القبلة
  // ============================================================

  Future<void> _getLocationAndCalculate() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'يرجى تفعيل خدمة الموقع GPS',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          throw Exception(
            'تم رفض إذن الموقع',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'إذن الموقع مرفوض دائماً. يرجى السماح بالموقع من إعدادات الهاتف.',
        );
      }

      final position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final qibla = _calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );

      final declination =
          _calculateDeclination(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _position = position;
        _qiblaDirection = qibla;
        _magneticDeclination = declination;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
        _loading = false;
      });
    }
  }

  // ============================================================
  // حساب اتجاه القبلة
  // ============================================================

  double _calculateQiblaDirection(
    double lat,
    double lng,
  ) {
    final latRad =
        lat * math.pi / 180;

    final lngRad =
        lng * math.pi / 180;

    final kaabaLatRad =
        kaabaLat * math.pi / 180;

    final kaabaLngRad =
        kaabaLng * math.pi / 180;

    final dLng =
        kaabaLngRad - lngRad;

    final y = math.sin(dLng);

    final x =
        math.cos(latRad) *
            math.tan(kaabaLatRad) -
        math.sin(latRad) *
            math.cos(dLng);

    var qibla =
        math.atan2(y, x) *
            180 /
            math.pi;

    if (qibla < 0) {
      qibla += 360;
    }

    return qibla;
  }

  // ============================================================
  // الانحراف المغناطيسي
  // ============================================================

  double _calculateDeclination(
    double lat,
    double lng,
  ) {
    try {
      final geoMag = GeoMag();

      final result = geoMag.calculate(
        lat,
        lng,
        0,
        DateTime.now(),
      );

      return result.dec;
    } catch (_) {
      return 0;
    }
  }

  // ============================================================
  // الاتجاه الحقيقي
  // ============================================================

  double get _trueHeading {
    /*
     * ملاحظة مهمة:
     *
     * flutter_compass يعطي heading بالنسبة للشمال
     * المغناطيسي في المنصات التي تعتمد على البوصلة
     * المغناطيسية.
     *
     * لذلك نضيف الانحراف المغناطيسي للوصول للشمال الحقيقي.
     */

    final value =
        _deviceHeading +
        _magneticDeclination;

    return (value + 360) % 360;
  }

  // ============================================================
  // زاوية القبلة بالنسبة للهاتف
  // ============================================================

  double _getQiblaAngle() {
    if (_qiblaDirection == null) {
      return 0;
    }

    var angle =
        _qiblaDirection! -
        _trueHeading;

    angle %= 360;

    if (angle < 0) {
      angle += 360;
    }

    return angle;
  }

  // ============================================================
  // الفرق بين اتجاه الهاتف والقبلة
  // ============================================================

  double _getAngleDifference() {
    if (_qiblaDirection == null) {
      return 180;
    }

    var difference =
        _qiblaDirection! -
        _trueHeading;

    while (difference < -180) {
      difference += 360;
    }

    while (difference > 180) {
      difference -= 360;
    }

    return difference.abs();
  }

  // ============================================================
  // دقة البوصلة
  // ============================================================

  bool get _needsCalibration {
    final accuracy = _headingAccuracy;

    if (accuracy == null) {
      return false;
    }

    return accuracy > 15;
  }

  // ============================================================
  // هل نحن باتجاه القبلة؟
  //
  // نستخدم عدة قراءات لتجنب ظهور الرسالة بسبب قراءة عابرة.
  // ============================================================

  bool _isFacingQibla() {
    final difference =
        _getAngleDifference();

    if (difference <= 5) {
      if (_qiblaMatchCounter < 5) {
        _qiblaMatchCounter++;
      }
    } else {
      _qiblaMatchCounter = 0;
    }

    return _qiblaMatchCounter >= 3;
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'اتجاه القبلة',
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _getLocationAndCalculate,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            30,
          ),
          children: [
            _buildHeader(),

            const SizedBox(height: 14),

            if (_needsCalibration)
              _buildCalibrationWarning(),

            if (!_compassAvailable &&
                !_loading)
              _buildCompassUnavailable(),

            if (_loading)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(50),
                  child:
                      CircularProgressIndicator(),
                ),
              ),

            if (_error != null)
              _buildError(),

            if (!_loading &&
                _error == null &&
                _qiblaDirection != null) ...[
              const SizedBox(height: 5),

              if (_isFacingQibla())
                _buildQiblaSuccess(),

              const SizedBox(height: 10),

              _buildProfessionalCompass(),

              const SizedBox(height: 20),

              _buildInfoCard(),

              const SizedBox(height: 14),

              if (_position != null)
                _buildLocationCard(),

              const SizedBox(height: 14),

              _buildInstructions(),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Header
  // ============================================================

  Widget _buildHeader() {
    return Card(
      elevation: 3,
      color:
          AppColors.lightGold.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
                  colors: [
                    AppColors.primaryGreen,
                    AppColors.primaryGreen
                        .withOpacity(0.65),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors
                        .primaryGreen
                        .withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.explore,
                size: 42,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'البوصلة الذكية للقبلة',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'حرّك الهاتف بشكل طبيعي حتى يتجه المؤشر نحو الكعبة',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color:
                    Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'حصراً على المذهب الشيعي الاثني عشري',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Calibration warning
  // ============================================================

  Widget _buildCalibrationWarning() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 30,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'حساس البوصلة يحتاج إلى معايرة. حرّك الهاتف بشكل رقم ٨ عدة مرات، وابتعد عن المعادن والسيارات ومكبرات الصوت.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Compass unavailable
  // ============================================================

  Widget _buildCompassUnavailable() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.explore_off,
            color: Colors.red,
            size: 28,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'لم يتم العثور على حساس بوصلة صالح في هذا الهاتف. قد لا يكون اتجاه القبلة متاحاً بدقة على هذا الجهاز.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Error
  // ============================================================

  Widget _buildError() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(
              Icons.location_off,
              color: Colors.red,
              size: 45,
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed:
                  _getLocationAndCalculate,
              icon: const Icon(
                Icons.refresh,
              ),
              label:
                  const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Qibla success
  // ============================================================

  Widget _buildQiblaSuccess() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFFE8F5E9),
            Color(0xFFC8E6C9),
          ],
        ),
        borderRadius:
            BorderRadius.circular(30),
        border: Border.all(
          color: Colors.green,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green
                .withOpacity(0.18),
            blurRadius: 12,
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 27,
          ),
          SizedBox(width: 8),
          Text(
            'أنت متجه نحو القبلة',
            style: TextStyle(
              color: Colors.green,
              fontWeight:
                  FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Professional Compass
  // ============================================================

  Widget _buildProfessionalCompass() {
    return Center(
      child: SizedBox(
        width: 350,
        height: 390,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // الظل الخارجي
            Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.30),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset:
                        const Offset(0, 10),
                  ),
                ],
              ),
            ),

            // جسم البوصلة
            Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    const RadialGradient(
                  center:
                      Alignment(-0.25, -0.3),
                  radius: 0.9,
                  colors: [
                    Color(0xFFFDFDFD),
                    Color(0xFFE7E7E7),
                    Color(0xFFBDBDBD),
                  ],
                ),
                border: Border.all(
                  color:
                      AppColors.primaryGreen,
                  width: 5,
                ),
              ),
            ),

            // الحلقة الذهبية
            Container(
              width: 315,
              height: 315,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gold,
                  width: 3,
                ),
              ),
            ),

            // البوصلة الداخلية الدوارة
            Transform.rotate(
              angle:
                  -_trueHeading *
                  math.pi /
                  180,
              child: SizedBox(
                width: 300,
                height: 300,
                child: Stack(
                  alignment:
                      Alignment.center,
                  children: [
                    _buildCompassFace(),
                    ..._buildDirectionMarkers(),
                    ..._buildDegreeMarkers(),
                  ],
                ),
              ),
            ),

            // مؤشر القبلة
            Transform.rotate(
              angle:
                  _getQiblaAngle() *
                  math.pi /
                  180,
              child: _buildQiblaPointer(),
            ),

            // الكعبة في نهاية مؤشر القبلة
            Transform.rotate(
              angle:
                  _getQiblaAngle() *
                  math.pi /
                  180,
              child: Positioned(
                top: 18,
                child:
                    _buildKaaba3D(),
              ),
            ),

            // مركز البوصلة
            Container(
              width: 34,
              height: 34,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                gradient:
                    const RadialGradient(
                  colors: [
                    Colors.white,
                    Colors.black87,
                  ],
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.45),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),

            // مؤشر N ثابت في أعلى الشاشة
            Positioned(
              top: 5,
              child:
                  _buildNorthIndicator(),
            ),

            // قراءة الدرجات
            Positioned(
              bottom: 0,
              child:
                  _buildHeadingBadge(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Compass Face
  // ============================================================

  Widget _buildCompassFace() {
    return Container(
      width: 285,
      height: 285,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            const RadialGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF1F1F1),
            Color(0xFFD7D7D7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.15),
            blurRadius: 12,
            inset: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // North indicator
  // ============================================================

  Widget _buildNorthIndicator() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient:
            const LinearGradient(
          begin:
              Alignment.topCenter,
          end:
              Alignment.bottomCenter,
          colors: [
            Color(0xFFE53935),
            Color(0xFFB71C1C),
          ],
        ),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Heading badge
  // ============================================================

  Widget _buildHeadingBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF263238),
            Color(0xFF455A64),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        '${_trueHeading.toStringAsFixed(0)}°',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // Qibla pointer
  // ============================================================

  Widget _buildQiblaPointer() {
    return SizedBox(
      width: 350,
      height: 350,
      child: Stack(
        alignment:
            Alignment.center,
        children: [
          Positioned(
            top: 70,
            child: Column(
              children: [
                // رأس المؤشر
                CustomPaint(
                  size:
                      const Size(42, 60),
                  painter:
                      _QiblaArrowPainter(
                    color:
                        AppColors.primaryGreen,
                  ),
                ),

                const SizedBox(height: 3),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      colors: [
                        AppColors
                            .primaryGreen,
                        AppColors
                            .primaryGreen
                            .withOpacity(
                          0.7,
                        ),
                      ],
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors
                            .black
                            .withOpacity(
                          0.3,
                        ),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                  child:
                      const Text(
                    'القبلة',
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3D Kaaba
  // ============================================================

  Widget _buildKaaba3D() {
    return SizedBox(
      width: 90,
      height: 95,
      child: CustomPaint(
        painter: _Kaaba3DPainter(),
      ),
    );
  }

  // ============================================================
  // Direction markers
  // ============================================================

  List<Widget> _buildDirectionMarkers() {
    final directions = [
      {
        'label': 'شمال',
        'angle': 0.0,
        'color': Colors.red,
      },
      {
        'label': 'شرق',
        'angle': 90.0,
        'color': Colors.black87,
      },
      {
        'label': 'جنوب',
        'angle': 180.0,
        'color': Colors.black87,
      },
      {
        'label': 'غرب',
        'angle': 270.0,
        'color': Colors.black87,
      },
    ];

    return directions.map((direction) {
      final angle =
          (direction['angle'] as double) *
              math.pi /
              180;

      final radius = 113.0;

      final x =
          radius * math.sin(angle);

      final y =
          -radius * math.cos(angle);

      return Positioned(
        left: 150 + x - 20,
        top: 150 + y - 10,
        child: Text(
          direction['label'] as String,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.bold,
            color:
                direction['color']
                    as Color,
          ),
        ),
      );
    }).toList();
  }

  // ============================================================
  // Degree markers
  // ============================================================

  List<Widget> _buildDegreeMarkers() {
    final markers = <Widget>[];

    for (int i = 0; i < 360; i += 10) {
      final angle =
          i * math.pi / 180;

      final isMajor =
          i % 30 == 0;

      final isCardinal =
          i % 90 == 0;

      final radius =
          isCardinal
              ? 132.0
              : 126.0;

      final x =
          radius * math.sin(angle);

      final y =
          -radius * math.cos(angle);

      markers.add(
        Positioned(
          left: 150 + x - 2,
          top: 150 + y - 2,
          child: Container(
            width:
                isCardinal
                    ? 5
                    : isMajor
                        ? 4
                        : 2,
            height:
                isCardinal
                    ? 5
                    : isMajor
                        ? 4
                        : 2,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              color:
                  isCardinal
                      ? Colors.black
                      : Colors.grey,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // ============================================================
  // Info card
  // ============================================================

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceEvenly,
          children: [
            _InfoBox(
              label: 'زاوية القبلة',
              value:
                  '${_qiblaDirection!.toStringAsFixed(1)}°',
              color:
                  AppColors.primaryGreen,
            ),
            _InfoBox(
              label: 'اتجاه الجهاز',
              value:
                  '${_trueHeading.toStringAsFixed(1)}°',
              color:
                  Colors.blue,
            ),
            _InfoBox(
              label: 'الفرق',
              value:
                  '${_getAngleDifference().toStringAsFixed(1)}°',
              color:
                  _isFacingQibla()
                      ? Colors.green
                      : AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Location card
  // ============================================================

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color:
                      AppColors.primaryGreen,
                ),
                SizedBox(width: 5),
                Text(
                  'موقعك الحالي',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              '${_position!.latitude.toStringAsFixed(4)}°N, '
              '${_position!.longitude.toStringAsFixed(4)}°E',
              textAlign:
                  TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              'الانحراف المغناطيسي: '
              '${_magneticDeclination.toStringAsFixed(2)}°',
              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _usingFallbackCompass
                  ? 'المستشعر: الوضع الاحتياطي'
                  : 'المستشعر: البوصلة المدمجة',
              style: TextStyle(
                fontSize: 12,
                color:
                    _usingFallbackCompass
                        ? Colors.orange[700]
                        : Colors.green[700],
              ),
            ),
            if (_headingAccuracy !=
                null) ...[
              const SizedBox(height: 4),
              Text(
                'دقة البوصلة: '
                '${_headingAccuracy!.toStringAsFixed(1)}°',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Instructions
  // ============================================================

  Widget _buildInstructions() {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'كيفية الحصول على أدق نتيجة',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '• اجعل الهاتف أفقياً قدر الإمكان.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            const Text(
              '• حرك الهاتف ببطء وليس بسرعة.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            const Text(
              '• إذا كانت البوصلة غير دقيقة، حرّك الهاتف بشكل رقم ٨ عدة مرات.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            const Text(
              '• ابتعد عن السيارات والمعادن ومكبرات الصوت والمغناطيس.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            const Text(
              '• لا تعتمد على البوصلة بالقرب من الأجهزة التي تسبب مجالاً مغناطيسياً قوياً.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            const Text(
              '• المؤشر الأخضر والكعبة يشيران إلى اتجاه القبلة.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            const Text(
              '• الزوايا محسوبة من الشمال الحقيقي باتجاه عقارب الساعة.',
              style: TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// Qibla Arrow Painter
// ================================================================

class _QiblaArrowPainter
    extends CustomPainter {
  final Color color;

  _QiblaArrowPainter({
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center =
        Offset(
      size.width / 2,
      size.height / 2,
    );

    final path = Path();

    path.moveTo(
      center.dx,
      0,
    );

    path.lineTo(
      size.width,
      size.height * 0.78,
    );

    path.lineTo(
      center.dx,
      size.height * 0.60,
    );

    path.lineTo(
      0,
      size.height * 0.78,
    );

    path.close();

    final shadowPaint =
        Paint()
          ..color =
              Colors.black
                  .withOpacity(0.25)
          ..style =
              PaintingStyle.fill;

    canvas.save();

    canvas.translate(
      2,
      3,
    );

    canvas.drawPath(
      path,
      shadowPaint,
    );

    canvas.restore();

    final paint =
        Paint()
          ..shader =
              LinearGradient(
            begin:
                Alignment.topCenter,
            end:
                Alignment.bottomCenter,
            colors: [
              color,
              color.withOpacity(
                0.55,
              ),
            ],
          ).createShader(
            Rect.fromLTWH(
              0,
              0,
              size.width,
              size.height,
            ),
          )
          ..style =
              PaintingStyle.fill;

    canvas.drawPath(
      path,
      paint,
    );

    final border =
        Paint()
          ..color =
              Colors.white
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              2;

    canvas.drawPath(
      path,
      border,
    );
  }

  @override
  bool shouldRepaint(
    covariant _QiblaArrowPainter oldDelegate,
  ) {
    return oldDelegate.color !=
        color;
  }
}

// ================================================================
// 3D Kaaba Painter
// ================================================================

class _Kaaba3DPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final cx =
        size.width / 2;

    // ------------------------------------------------------------
    // ظل الكعبة
    // ------------------------------------------------------------

    final shadowPaint =
        Paint()
          ..color =
              Colors.black
                  .withOpacity(0.25)
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            5,
          );

    canvas.drawOval(
      Rect.fromCenter(
        center:
            Offset(
          cx,
          size.height - 10,
        ),
        width: 65,
        height: 15,
      ),
      shadowPaint,
    );

    // ------------------------------------------------------------
    // الوجه الأمامي
    // ------------------------------------------------------------

    final front =
        Path();

    front.moveTo(
      18,
      31,
    );

    front.lineTo(
      68,
      31,
    );

    front.lineTo(
      68,
      76,
    );

    front.lineTo(
      18,
      76,
    );

    front.close();

    final frontPaint =
        Paint()
          ..shader =
              const LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(0xFF292929),
              Color(0xFF050505),
            ],
          ).createShader(
            const Rect.fromLTWH(
              18,
              31,
              50,
              45,
            ),
          );

    canvas.drawPath(
      front,
      frontPaint,
    );

    // ------------------------------------------------------------
    // الجانب الأيمن
    // ------------------------------------------------------------

    final side =
        Path();

    side.moveTo(
      68,
      31,
    );

    side.lineTo(
      80,
      24,
    );

    side.lineTo(
      80,
      68,
    );

    side.lineTo(
      68,
      76,
    );

    side.close();

    final sidePaint =
        Paint()
          ..shader =
              const LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(0xFF111111),
              Color(0xFF000000),
            ],
          ).createShader(
            const Rect.fromLTWH(
              68,
              24,
              12,
              52,
            ),
          );

    canvas.drawPath(
      side,
      sidePaint,
    );

    // ------------------------------------------------------------
    // السطح العلوي
    // ------------------------------------------------------------

    final top =
        Path();

    top.moveTo(
      18,
      31,
    );

    top.lineTo(
      30,
      23,
    );

    top.lineTo(
      80,
      24,
    );

    top.lineTo(
      68,
      31,
    );

    top.close();

    final topPaint =
        Paint()
          ..shader =
              const LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              Color(0xFF4A4A4A),
              Color(0xFF181818),
            ],
          ).createShader(
            const Rect.fromLTWH(
              18,
              23,
              62,
              8,
            ),
          );

    canvas.drawPath(
      top,
      topPaint,
    );

    // ------------------------------------------------------------
    // حزام الكعبة الذهبي
    // ------------------------------------------------------------

    final beltPaint =
        Paint()
          ..color =
              const Color(
            0xFFD4AF37,
          )
          ..style =
              PaintingStyle.fill;

    canvas.drawRect(
      const Rect.fromLTWH(
        18,
        43,
        50,
        6,
      ),
      beltPaint,
    );

    // ------------------------------------------------------------
    // باب الكعبة
    // ------------------------------------------------------------

    final door =
        Rect.fromLTWH(
      36,
      51,
      14,
      25,
    );

    final doorPaint =
        Paint()
          ..shader =
              const LinearGradient(
            colors: [
              Color(0xFFFFD54F),
              Color(0xFF8D6E00),
            ],
          ).createShader(
            door,
          );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        door,
        const Radius.circular(
          2,
        ),
      ),
      doorPaint,
    );

    // ------------------------------------------------------------
    // إطار الباب
    // ------------------------------------------------------------

    final doorBorder =
        Paint()
          ..color =
              const Color(
            0xFFFFE082,
          )
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
              1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        door,
        const Radius.circular(
          2,
        ),
      ),
      doorBorder,
    );

    // ------------------------------------------------------------
    // خط ذهبي سفلي
    // ------------------------------------------------------------

    final bottomPaint =
        Paint()
          ..color =
              const Color(
            0xFFD4AF37,
          )
          ..strokeWidth =
              2;

    canvas.drawLine(
      const Offset(
        18,
        76,
      ),
      const Offset(
        68,
        76,
      ),
      bottomPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _Kaaba3DPainter oldDelegate,
  ) {
    return false;
  }
}

// ================================================================
// Info Box
// ================================================================

class _InfoBox
    extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
                Colors.grey[600],
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
