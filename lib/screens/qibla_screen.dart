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
  // إحداثيات الكعبة
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

  double _deviceHeading = 0.0;
  double _smoothHeading = 0.0;

  double _magneticDeclination = 0.0;

  double? _headingAccuracy;

  bool _compassAvailable = false;
  bool _usingFallbackCompass = false;

  bool _hasFirstHeading = false;

  // آخر قراءات المستشعرات
  AccelerometerEvent? _lastAccelerometer;
  MagnetometerEvent? _lastMagnetometer;

  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;

  AnimationController? _animationController;

  // ============================================================
  // Init
  // ============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
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
  //
  // نستخدم flutter_compass أولاً.
  //
  // لا نستخدم fallback إلا إذا لم تتوفر البوصلة الأساسية.
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

          if (heading == null ||
              heading.isNaN ||
              heading.isInfinite) {
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
  // الوضع الاحتياطي
  //
  // Accelerometer + Magnetometer
  //
  // مهم:
  // لا نستخدم atan2(magnetometer.y, magnetometer.x)
  // لأنه غير دقيق عند ميل الهاتف.
  // ============================================================

  void _startSensorFallback() {
    if (_usingFallbackCompass) return;

    _usingFallbackCompass = true;

    try {
      _accelerometerSubscription ??=
          accelerometerEventStream().listen(
        (event) {
          _lastAccelerometer = event;
          _calculateFallbackHeading();
        },
      );

      _magnetometerSubscription ??=
          magnetometerEventStream().listen(
        (event) {
          _lastMagnetometer = event;
          _calculateFallbackHeading();
        },
      );
    } catch (_) {
      _compassAvailable = false;
    }
  }

  // ============================================================
  // حساب الاتجاه الاحتياطي
  //
  // يتم تصحيح الميل باستخدام الجاذبية.
  // ============================================================

  void _calculateFallbackHeading() {
    if (!mounted) return;

    final acc = _lastAccelerometer;
    final mag = _lastMagnetometer;

    if (acc == null || mag == null) return;

    try {
      // ----------------------------------------------------------
      // Gravity
      // ----------------------------------------------------------

      double gx = acc.x;
      double gy = acc.y;
      double gz = acc.z;

      final gLength = math.sqrt(
        gx * gx +
            gy * gy +
            gz * gz,
      );

      if (gLength < 0.5) return;

      gx /= gLength;
      gy /= gLength;
      gz /= gLength;

      // ----------------------------------------------------------
      // Magnetic field
      // ----------------------------------------------------------

      double mx = mag.x;
      double my = mag.y;
      double mz = mag.z;

      final mLength = math.sqrt(
        mx * mx +
            my * my +
            mz * mz,
      );

      if (mLength < 5) return;

      mx /= mLength;
      my /= mLength;
      mz /= mLength;

      // ----------------------------------------------------------
      // H = magnetic × gravity
      // ----------------------------------------------------------

      double hx =
          my * gz -
          mz * gy;

      double hy =
          mz * gx -
          mx * gz;

      double hz =
          mx * gy -
          my * gx;

      final hLength = math.sqrt(
        hx * hx +
            hy * hy +
            hz * hz,
      );

      if (hLength < 0.05) return;

      hx /= hLength;
      hy /= hLength;
      hz /= hLength;

      // ----------------------------------------------------------
      // North = gravity × H
      // ----------------------------------------------------------

      final nx =
          gy * hz -
          gz * hy;

      final ny =
          gz * hx -
          gx * hz;

      final nz =
          gx * hy -
          gy * hx;

      // ----------------------------------------------------------
      // اتجاه الهاتف
      //
      // محور X هو اتجاه الشرق
      // محور Y هو اتجاه الشمال
      // ----------------------------------------------------------

      // اتجاه أعلى الهاتف (+Y) بالنسبة إلى الشمال/الشرق.
      // الخطأ السابق كان يستخدم hx/nx، أي محور X، مما يسبب
      // انحرافاً واضحاً في الاتجاه عند استخدام الوضع الاحتياطي.
      // في الوضع العمودي للهاتف نستخدم مركبتي الشرق والشمال
      // لمحور Y: atan2(E_y, N_y).
      var heading =
          math.atan2(hy, ny) *
          180 /
          math.pi;

      if (heading < 0) {
        heading += 360;
      }

      if (heading >= 360) {
        heading -= 360;
      }

      _compassAvailable = true;

      _updateHeading(heading);
    } catch (_) {
      // قراءة غير صالحة
    }
  }

  // ============================================================
  // تحديث الاتجاه
  // ============================================================

  void _updateHeading(double heading) {
    if (heading.isNaN ||
        heading.isInfinite) {
      return;
    }

    heading =
        (heading + 360) % 360;

    if (!_hasFirstHeading) {
      _smoothHeading = heading;
      _deviceHeading = heading;
      _hasFirstHeading = true;

      if (mounted) {
        setState(() {});
      }

      return;
    }

    // ----------------------------------------------------------
    // فلتر ناعم
    //
    // قيمة أكبر = استجابة أسرع
    // قيمة أصغر = ثبات أكبر
    // ----------------------------------------------------------

    _smoothHeading = _lerpAngle(
      _smoothHeading,
      heading,
      0.22,
    );

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
    var difference =
        target - current;

    while (difference < -180) {
      difference += 360;
    }

    while (difference > 180) {
      difference -= 360;
    }

    return (
      current +
      difference * factor +
      360
    ) % 360;
  }

  // ============================================================
  // الموقع
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
          'يرجى تفعيل خدمة الموقع GPS.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();

        if (permission ==
            LocationPermission.denied) {
          throw Exception(
            'تم رفض إذن الموقع.',
          );
        }
      }

      if (permission ==
          LocationPermission.deniedForever) {
        throw Exception(
          'إذن الموقع مرفوض دائماً. يرجى السماح بالموقع من إعدادات الهاتف.',
        );
      }

      final position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );

      final qibla =
          _calculateQiblaDirection(
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
        _magneticDeclination =
            declination;
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

    final y =
        math.sin(dLng);

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
  // Magnetic declination
  // ============================================================

  double _calculateDeclination(
    double lat,
    double lng,
  ) {
    try {
      final geoMag = GeoMag();

      final result =
          geoMag.calculate(
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
  //
  // flutter_compass يعيد الاتجاه المغناطيسي على Android.
  // نضيف الانحراف المغناطيسي للحصول على الاتجاه الحقيقي.
  // ============================================================

  double get _trueHeading {
    // flutter_compass على Android يعطينا الاتجاه المغناطيسي.
    // نضيف الانحراف المغناطيسي (East positive / West negative)
    // للحصول على الاتجاه الجغرافي الحقيقي.
    final value = _deviceHeading + _magneticDeclination;
    return (value + 360) % 360;
  }

  // ============================================================
  // زاوية السهم
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
  // فرق الاتجاه
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
  // معايرة
  // ============================================================

  bool get _needsCalibration {
    final accuracy =
        _headingAccuracy;

    if (accuracy == null) {
      return false;
    }

    return accuracy > 15;
  }

  // ============================================================
  // هل باتجاه القبلة؟
  // ============================================================

  bool _isFacingQibla() {
    return _getAngleDifference() <= 5;
  }

  // ============================================================
  // BUILD
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
        onRefresh:
            _getLocationAndCalculate,
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
              if (_isFacingQibla())
                _buildQiblaSuccess(),

              const SizedBox(height: 8),

              _buildProfessionalCompass(),

              const SizedBox(height: 18),

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
      elevation: 4,
      color:
          AppColors.lightGold
              .withOpacity(0.3),
      shape:
          RoundedRectangleBorder(
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
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
                  colors: [
                    AppColors
                        .primaryGreen,
                    AppColors
                        .primaryGreen
                        .withOpacity(
                      0.65,
                    ),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors
                        .primaryGreen
                        .withOpacity(
                      0.3,
                    ),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child:
                  const Icon(
                Icons.explore,
                size: 42,
                color:
                    Colors.white,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'البوصلة الذكية للقبلة',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
                color:
                    Colors.black87,
              ),
            ),
            const SizedBox(
              height: 7,
            ),
            const Text(
              'حرّك الهاتف ببطء حتى يصبح السهم الأخضر باتجاه الكعبة.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color:
                    Colors.black87,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            const Text(
              'حصراً على المذهب الشيعي الاثني عشري',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.black87,
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
      decoration:
          BoxDecoration(
        color:
            Colors.orange[50],
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange,
          width: 1.5,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 30,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'دقة البوصلة منخفضة حالياً. حرّك الهاتف ببطء على شكل رقم ٨ عدة مرات، ثم أبعده عن المعادن والسيارات ومكبرات الصوت.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color:
                    Colors.black87,
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
      decoration:
          BoxDecoration(
        color: Colors.red[50],
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.explore_off,
            color: Colors.red,
            size: 28,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'لم يتم العثور على حساس بوصلة صالح في هذا الهاتف. قد لا يكون تحديد اتجاه القبلة متاحاً بدقة على هذا الجهاز.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color:
                    Colors.black87,
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
            const SizedBox(
              height: 10,
            ),
            Text(
              _error!,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                color:
                    Colors.black87,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            ElevatedButton.icon(
              onPressed:
                  _getLocationAndCalculate,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'إعادة المحاولة',
              ),
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
      decoration:
          BoxDecoration(
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
  // البوصلة الاحترافية
  // ============================================================

  Widget _buildProfessionalCompass() {
    return Center(
      child: SizedBox(
        width: 350,
        height: 385,
        child: Stack(
          alignment:
              Alignment.center,
          children: [
            // ----------------------------------------------------
            // الظل
            // ----------------------------------------------------

            Container(
              width: 340,
              height: 340,
              decoration:
                  const BoxDecoration(
                shape:
                    BoxShape.circle,
              ),
              child: DecoratedBox(
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black38,
                      blurRadius: 28,
                      spreadRadius: 4,
                      offset:
                          Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),

            // ----------------------------------------------------
            // جسم البوصلة
            // ----------------------------------------------------

            Container(
              width: 340,
              height: 340,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                gradient:
                    const RadialGradient(
                  center:
                      Alignment(
                    -0.25,
                    -0.30,
                  ),
                  radius: 0.95,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFE9E9E9),
                    Color(0xFFB8B8B8),
                  ],
                ),
                border:
                    Border.all(
                  color:
                      AppColors
                          .primaryGreen,
                  width: 5,
                ),
              ),
            ),

            // ----------------------------------------------------
            // الحلقة الذهبية
            // ----------------------------------------------------

            Container(
              width: 315,
              height: 315,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                border:
                    Border.all(
                  color:
                      AppColors.gold,
                  width: 3,
                ),
              ),
            ),

            // ----------------------------------------------------
            // وجه البوصلة الدوار
            // ----------------------------------------------------

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

            // ----------------------------------------------------
            // سهم القبلة
            //
            // السهم هو الذي يدور.
            // ----------------------------------------------------

            Transform.rotate(
              angle:
                  _getQiblaAngle() *
                  math.pi /
                  180,
              child:
                  _buildQiblaPointer(),
            ),

            // ----------------------------------------------------
            // الكعبة
            //
            // مهمة جداً:
            //
            // الكعبة الآن ثابتة في أعلى الدائرة.
            // لا توجد داخل Transform.rotate.
            //
            // لذلك لا تدور حول نفسها.
            // ----------------------------------------------------

            Positioned(
              top: 25,
              child:
                  _buildKaaba3D(),
            ),

            // ----------------------------------------------------
            // مركز البوصلة
            // ----------------------------------------------------

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
                border:
                    Border.all(
                  color:
                      Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black45,
                    blurRadius: 10,
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // N ثابت
            // ----------------------------------------------------

            Positioned(
              top: 0,
              child:
                  _buildNorthIndicator(),
            ),

            // ----------------------------------------------------
            // قراءة الاتجاه
            // ----------------------------------------------------

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
  // وجه البوصلة
  // ============================================================

  Widget _buildCompassFace() {
    return Container(
      width: 285,
      height: 285,
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
        gradient:
            const RadialGradient(
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF1F1F1),
            Color(0xFFD4D4D4),
          ],
        ),
        border:
            Border.all(
          color:
              Colors.black12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black26,
            blurRadius: 12,
            offset:
                Offset(0, 3),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // N
  // ============================================================

  Widget _buildNorthIndicator() {
    return Container(
      width: 48,
      height: 48,
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
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
        border:
            Border.all(
          color:
              Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black38,
            blurRadius: 8,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'N',
          style: TextStyle(
            color:
                Colors.white,
            fontSize: 21,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // قراءة الاتجاه
  // ============================================================

  Widget _buildHeadingBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFF263238),
            Color(0xFF455A64),
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
        border:
            Border.all(
          color:
              AppColors.gold,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black38,
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        '${_trueHeading.toStringAsFixed(0)}°',
        style:
            const TextStyle(
          color:
              Colors.white,
          fontSize: 16,
          fontWeight:
              FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // مؤشر القبلة
  //
  // رأس السهم يصل إلى الكعبة عندما تكون القبلة أمام المستخدم.
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
            top: 72,
            child: Column(
              children: [
                CustomPaint(
                  size:
                      const Size(
                    44,
                    64,
                  ),
                  painter:
                      _QiblaArrowPainter(
                    color:
                        AppColors
                            .primaryGreen,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 13,
                    vertical: 6,
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
                          0.70,
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
                        color:
                            Colors.black38,
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
  // الكعبة 3D
  //
  // ثابتة في مكانها.
  // لا تدور.
  // ============================================================

  Widget _buildKaaba3D() {
    return SizedBox(
      width: 78,
      height: 78,
      child: CustomPaint(
        painter:
            _Kaaba3DPainter(),
      ),
    );
  }

  // ============================================================
  // اتجاهات البوصلة
  // ============================================================

  List<Widget>
      _buildDirectionMarkers() {
    final directions = [
      {
        'label': 'شمال',
        'angle': 0.0,
        'color':
            Colors.red,
      },
      {
        'label': 'شرق',
        'angle': 90.0,
        'color':
            Colors.black87,
      },
      {
        'label': 'جنوب',
        'angle': 180.0,
        'color':
            Colors.black87,
      },
      {
        'label': 'غرب',
        'angle': 270.0,
        'color':
            Colors.black87,
      },
    ];

    return directions.map(
      (direction) {
        final angle =
            (direction['angle']
                    as double) *
                math.pi /
                180;

        const radius =
            112.0;

        final x =
            radius *
            math.sin(angle);

        final y =
            -radius *
            math.cos(angle);

        return Positioned(
          left:
              150 + x - 22,
          top:
              150 + y - 10,
          child: Text(
            direction['label']
                as String,
            style:
                TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.bold,
              color:
                  direction['color']
                      as Color,
            ),
          ),
        );
      },
    ).toList();
  }

  // ============================================================
  // علامات الدرجات
  // ============================================================

  List<Widget>
      _buildDegreeMarkers() {
    final markers =
        <Widget>[];

    for (
      int i = 0;
      i < 360;
      i += 10
    ) {
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
          radius *
          math.sin(angle);

      final y =
          -radius *
          math.cos(angle);

      markers.add(
        Positioned(
          left:
              150 + x - 2,
          top:
              150 + y - 2,
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
                      ? Colors.black87
                      : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // ============================================================
  // معلومات
  // ============================================================

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
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
              label:
                  'زاوية القبلة',
              value:
                  '${_qiblaDirection!.toStringAsFixed(1)}°',
              color:
                  AppColors
                      .primaryGreen,
            ),
            _InfoBox(
              label:
                  'اتجاه الجهاز',
              value:
                  '${_trueHeading.toStringAsFixed(1)}°',
              color:
                  Colors.blue,
            ),
            _InfoBox(
              label:
                  'الفرق',
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
  // الموقع
  // ============================================================

  Widget _buildLocationCard() {
    return Card(
      elevation: 2,
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
                      AppColors
                          .primaryGreen,
                ),
                SizedBox(width: 5),
                Text(
                  'موقعك الحالي',
                  style:
                      TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 9,
            ),
            Text(
              '${_position!.latitude.toStringAsFixed(4)}°N, '
              '${_position!.longitude.toStringAsFixed(4)}°E',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.black87,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              'الانحراف المغناطيسي: '
              '${_magneticDeclination.toStringAsFixed(2)}°',
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    Colors.black87,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              _usingFallbackCompass
                  ? 'المستشعر: الوضع الاحتياطي'
                  : 'المستشعر: البوصلة المدمجة',
              style:
                  TextStyle(
                fontSize: 12,
                color:
                    _usingFallbackCompass
                        ? Colors.orange[800]
                        : Colors.green[800],
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            if (_headingAccuracy !=
                null) ...[
              const SizedBox(
                height: 5,
              ),
              Text(
                'دقة حساس البوصلة: '
                '${_headingAccuracy!.toStringAsFixed(1)}°',
                style:
                    const TextStyle(
                  fontSize: 12,
                  color:
                      Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // الملاحظات
  // ============================================================

  Widget _buildInstructions() {
    const textStyle =
        TextStyle(
      fontSize: 13,
      height: 1.9,
      color: Colors.black87,
      fontWeight:
          FontWeight.w500,
    );

    return Card(
      color:
          const Color(0xFFF5F5F5),
      elevation: 2,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            const Text(
              'ملاحظات للحصول على أدق نتيجة',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
                color:
                    Colors.black,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const Text(
              '• اجعل الهاتف أفقياً قدر الإمكان.',
              style: textStyle,
            ),
            const Text(
              '• حرّك الهاتف ببطء وليس بسرعة.',
              style: textStyle,
            ),
            const Text(
              '• عند عدم ثبات الاتجاه، حرّك الهاتف على شكل رقم ٨ عدة مرات لمعايرة الحساس.',
              style: textStyle,
            ),
            const Text(
              '• ابتعد عن السيارات والمعادن والمغناطيس ومكبرات الصوت.',
              style: textStyle,
            ),
            const Text(
              '• لا تستخدم البوصلة بجانب الأجهزة التي تولد مجالاً مغناطيسياً قوياً.',
              style: textStyle,
            ),
            const Text(
              '• عندما يصبح السهم الأخضر باتجاه الكعبة، تكون القبلة أمامك.',
              style: textStyle,
            ),
            const Text(
              '• الزوايا محسوبة من الشمال الحقيقي باتجاه عقارب الساعة.',
              style: textStyle,
            ),
            const SizedBox(
              height: 8,
            ),
            Container(
              padding:
                  const EdgeInsets.all(
                10,
              ),
              decoration:
                  BoxDecoration(
                color:
                    Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                border:
                    Border.all(
                  color:
                      Colors.black12,
                ),
              ),
              child:
                  const Text(
                'تنبيه: دقة البوصلة تعتمد على وجود حساس مغناطيسي حقيقي في الهاتف. إذا كان الهاتف لا يحتوي على هذا الحساس فلن يستطيع التطبيق تحديد الاتجاه المغناطيسي بدقة مهما كان تصميم البوصلة.',
                style:
                    TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  color:
                      Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// سهم القبلة
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

    final path =
        Path();

    path.moveTo(
      center.dx,
      0,
    );

    path.lineTo(
      size.width,
      size.height *
          0.78,
    );

    path.lineTo(
      center.dx,
      size.height *
          0.60,
    );

    path.lineTo(
      0,
      size.height *
          0.78,
    );

    path.close();

    // ظل
    final shadowPaint =
        Paint()
          ..color =
              Colors.black
                  .withOpacity(
            0.25,
          )
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

    // جسم السهم
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

    // الحافة
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
    covariant
        _QiblaArrowPainter
            oldDelegate,
  ) {
    return oldDelegate.color !=
        color;
  }
}

// ================================================================
// مجسم الكعبة
// ================================================================

class _Kaaba3DPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final scale =
        size.width / 90;

    canvas.save();

    canvas.scale(
      scale,
      scale,
    );

    // ------------------------------------------------------------
    // الظل
    // ------------------------------------------------------------

    final shadowPaint =
        Paint()
          ..color =
              Colors.black
                  .withOpacity(
            0.25,
          )
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            4,
          );

    canvas.drawOval(
      Rect.fromCenter(
        center:
            const Offset(
          45,
          76,
        ),
        width: 60,
        height: 12,
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
      30,
    );

    front.lineTo(
      67,
      30,
    );

    front.lineTo(
      67,
      74,
    );

    front.lineTo(
      18,
      74,
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
              30,
              49,
              44,
            ),
          );

    canvas.drawPath(
      front,
      frontPaint,
    );

    // ------------------------------------------------------------
    // الجانب
    // ------------------------------------------------------------

    final side =
        Path();

    side.moveTo(
      67,
      30,
    );

    side.lineTo(
      78,
      24,
    );

    side.lineTo(
      78,
      67,
    );

    side.lineTo(
      67,
      74,
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
              Color(0xFF151515),
              Color(0xFF000000),
            ],
          ).createShader(
            const Rect.fromLTWH(
              67,
              24,
              11,
              50,
            ),
          );

    canvas.drawPath(
      side,
      sidePaint,
    );

    // ------------------------------------------------------------
    // السطح
    // ------------------------------------------------------------

    final top =
        Path();

    top.moveTo(
      18,
      30,
    );

    top.lineTo(
      29,
      23,
    );

    top.lineTo(
      78,
      24,
    );

    top.lineTo(
      67,
      30,
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
              Color(0xFF505050),
              Color(0xFF191919),
            ],
          ).createShader(
            const Rect.fromLTWH(
              18,
              23,
              60,
              7,
            ),
          );

    canvas.drawPath(
      top,
      topPaint,
    );

    // ------------------------------------------------------------
    // الحزام الذهبي
    // ------------------------------------------------------------

    final beltPaint =
        Paint()
          ..color =
              const Color(
            0xFFD4AF37,
          );

    canvas.drawRect(
      const Rect.fromLTWH(
        18,
        42,
        49,
        6,
      ),
      beltPaint,
    );

    // ------------------------------------------------------------
    // باب الكعبة
    // ------------------------------------------------------------

    final door =
        Rect.fromLTWH(
      35,
      50,
      14,
      24,
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

    // إطار الباب
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
    // خط سفلي
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
        74,
      ),
      const Offset(
        67,
        74,
      ),
      bottomPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant
        _Kaaba3DPainter
            oldDelegate,
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
          style:
              const TextStyle(
            fontSize: 11,
            color:
                Colors.black87,
            fontWeight:
                FontWeight.w500,
          ),
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          style:
              TextStyle(
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
