import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geomag/geomag.dart';

import '../theme.dart';

/// ===============================================================
/// مكان مقدس
/// ===============================================================

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

/// ===============================================================
/// الأماكن المقدسة
///
/// الإحداثيات هنا تمثل موقع المبنى/المرقد أو المسجد نفسه،
/// وليس مركز المدينة.
/// ===============================================================

const List<SacredPlace> sacredPlaces = [
  SacredPlace(
    name: 'المسجد النبوي الشريف',
    subtitle: 'المدينة المنورة',
    lat: 24.46865,
    lng: 39.61117,
  ),

  SacredPlace(
    name: 'البقيع الشريف',
    subtitle:
        'مراقد أئمة أهل البيت (ع) - المدينة المنورة',
    lat: 24.46667,
    lng: 39.61633,
  ),

  SacredPlace(
    name: 'مرقد الإمام علي (ع)',
    subtitle: 'النجف الأشرف',
    lat: 31.99600,
    lng: 44.31430,
  ),

  SacredPlace(
    name: 'مرقد الإمام الحسين (ع)',
    subtitle: 'كربلاء المقدسة',
    lat: 32.58333,
    lng: 44.04167,
  ),

  SacredPlace(
    name: 'مرقد الإمامين الكاظم والجواد (ع)',
    subtitle: 'الكاظمية - بغداد',
    lat: 33.38003,
    lng: 44.33810,
  ),

  SacredPlace(
    name: 'مرقد الإمامين الهادي والعسكري (ع)',
    subtitle: 'سامراء',
    lat: 34.19893,
    lng: 43.87353,
  ),

  SacredPlace(
    name: 'سرداب الغيبة - سامراء',
    subtitle: 'مقام الإمام المهدي (عج)',
    lat: 34.19893,
    lng: 43.87353,
  ),

  SacredPlace(
    name: 'مرقد الإمام الرضا (ع)',
    subtitle: 'مشهد المقدسة - إيران',
    lat: 36.28797,
    lng: 59.61569,
  ),

  SacredPlace(
    name: 'مرقد السيدة زينب (ع)',
    subtitle: 'السيدة زينب - ريف دمشق - سوريا',
    lat: 33.44444,
    lng: 36.34083,
  ),

  SacredPlace(
    name: 'مسجد الكوفة الأعظم',
    subtitle: 'الكوفة - النجف - العراق',
    lat: 32.02906,
    lng: 44.40120,
  ),

  SacredPlace(
    name: 'مسجد السهلة المعظم',
    subtitle: 'الكوفة - النجف - العراق',
    lat: 32.03897,
    lng: 44.37975,
  ),
];

/// ===============================================================
/// الشاشة
/// ===============================================================

class ShrinesCompassScreen extends StatefulWidget {
  const ShrinesCompassScreen({super.key});

  @override
  State<ShrinesCompassScreen> createState() =>
      _ShrinesCompassScreenState();
}

class _ShrinesCompassScreenState
    extends State<ShrinesCompassScreen> {
  // =============================================================
  // الحالة
  // =============================================================

  bool _loading = true;
  String? _error;

  Position? _position;

  double? _targetDirection;

  /// الاتجاه الحقيقي للجهاز
  double _deviceHeading = 0;

  /// آخر اتجاه ناعم
  double _smoothHeading = 0;

  /// الانحراف المغناطيسي
  double _declination = 0;

  /// دقة البوصلة
  double? _headingAccuracy;

  bool _compassAvailable = false;
  bool _usingFallback = false;

  bool _hasFirstHeading = false;

  /// عدد القراءات المتتالية الموافقة للهدف
  int _targetMatchCounter = 0;

  SacredPlace _selectedPlace = sacredPlaces.first;

  // =============================================================
  // Sensor subscriptions
  // =============================================================

  StreamSubscription<CompassEvent>? _compassSubscription;

  StreamSubscription<AccelerometerEvent>?
      _accelerometerSubscription;

  StreamSubscription<MagnetometerEvent>?
      _magnetometerSubscription;

  // =============================================================
  // آخر قراءات المستشعرات
  // =============================================================

  AccelerometerEvent? _lastAccelerometer;
  MagnetometerEvent? _lastMagnetometer;

  // =============================================================
  // Init
  // =============================================================

  @override
  void initState() {
    super.initState();

    _getLocationAndCalculate();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();

    super.dispose();
  }

  // =============================================================
  // بدء البوصلة
  // =============================================================

  Future<void> _initCompass() async {
    try {
      final events = FlutterCompass.events;

      if (events == null) {
        _startTiltCompensatedFallback();
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
          _usingFallback = false;

          _headingAccuracy = event.accuracy;

          _updateHeading(
            _toTrueHeading(heading),
          );
        },
        onError: (_) {
          _startTiltCompensatedFallback();
        },
        cancelOnError: false,
      );
    } catch (_) {
      _startTiltCompensatedFallback();
    }
  }

  // =============================================================
  // Fallback
  //
  // مهم:
  //
  // لا نستخدم:
  //
  // atan2(magnetometer.y, magnetometer.x)
  //
  // لأنها تصبح غير دقيقة جدًا عند ميل الهاتف.
  //
  // بدل ذلك نستخدم Accelerometer + Magnetometer
  // مع تعويض الميل Tilt Compensation.
  // =============================================================

  void _startTiltCompensatedFallback() {
    if (_usingFallback) return;

    _usingFallback = true;

    _accelerometerSubscription?.cancel();
    _magnetometerSubscription?.cancel();

    try {
      _accelerometerSubscription =
          accelerometerEventStream().listen(
        (event) {
          _lastAccelerometer = event;
          _calculateTiltCompensatedHeading();
        },
        onError: (_) {
          _compassAvailable = false;
        },
      );

      _magnetometerSubscription =
          magnetometerEventStream().listen(
        (event) {
          _lastMagnetometer = event;
          _calculateTiltCompensatedHeading();
        },
        onError: (_) {
          _compassAvailable = false;
        },
      );
    } catch (_) {
      _compassAvailable = false;
    }
  }

  // =============================================================
  // حساب البوصلة مع تعويض الميل
  // =============================================================

  void _calculateTiltCompensatedHeading() {
    if (!mounted) return;

    final acc = _lastAccelerometer;
    final mag = _lastMagnetometer;

    if (acc == null || mag == null) return;

    try {
      // ----------------------------------------------------------
      // Gravity
      // ----------------------------------------------------------

      double ax = acc.x;
      double ay = acc.y;
      double az = acc.z;

      final aLength = math.sqrt(
        ax * ax +
            ay * ay +
            az * az,
      );

      if (aLength < 0.1) return;

      ax /= aLength;
      ay /= aLength;
      az /= aLength;

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

      if (mLength < 0.1) return;

      mx /= mLength;
      my /= mLength;
      mz /= mLength;

      // ----------------------------------------------------------
      // East = Magnetic × Gravity
      // ----------------------------------------------------------

      double ex =
          my * az -
          mz * ay;

      double ey =
          mz * ax -
          mx * az;

      double ez =
          mx * ay -
          my * ax;

      final eLength = math.sqrt(
        ex * ex +
            ey * ey +
            ez * ez,
      );

      if (eLength < 0.01) return;

      ex /= eLength;
      ey /= eLength;
      ez /= eLength;

      // ----------------------------------------------------------
      // North = Gravity × East
      // ----------------------------------------------------------

      double nx =
          ay * ez -
          az * ey;

      double ny =
          az * ex -
          ax * ez;

      double nz =
          ax * ey -
          ay * ex;

      final nLength = math.sqrt(
        nx * nx +
            ny * ny +
            nz * nz,
      );

      if (nLength < 0.01) return;

      nx /= nLength;
      ny /= nLength;
      nz /= nLength;

      // ----------------------------------------------------------
      // اتجاه أعلى الهاتف Y بالنسبة للشمال
      //
      // يتم إسقاط محور Y على المستوى الأفقي.
      //
      // هذا يعوض ميل الهاتف.
      // ----------------------------------------------------------

      final headingRad =
          math.atan2(
            ey,
            ny,
          );

      var heading =
          headingRad *
          180 /
          math.pi;

      if (heading < 0) {
        heading += 360;
      }

      heading %= 360;

      _compassAvailable = true;

      _headingAccuracy = null;

      _updateHeading(
        _toTrueHeading(heading),
      );
    } catch (_) {
      // قراءة غير صالحة
    }
  }

  // =============================================================
  // تحويل الشمال المغناطيسي إلى الحقيقي
  // =============================================================

  double _toTrueHeading(
    double magneticHeading,
  ) {
    var trueHeading =
        magneticHeading +
        _declination;

    trueHeading %= 360;

    if (trueHeading < 0) {
      trueHeading += 360;
    }

    return trueHeading;
  }

  // =============================================================
  // تحديث الاتجاه
  // =============================================================

  void _updateHeading(
    double heading,
  ) {
    if (heading.isNaN ||
        heading.isInfinite) {
      return;
    }

    heading =
        (heading + 360) % 360;

    // أول قراءة:
    // لا نبدأ من صفر حتى لا يحدث دوران وهمي طويل.
    if (!_hasFirstHeading) {
      _hasFirstHeading = true;
      _smoothHeading = heading;
    } else {
      _smoothHeading =
          _lerpAngle(
        _smoothHeading,
        heading,
        0.18,
      );
    }

    _deviceHeading =
        _smoothHeading;

    if (mounted) {
      setState(() {});
    }
  }

  // =============================================================
  // تنعيم زاوي صحيح
  // =============================================================

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

    return (current +
            difference * factor +
            360) %
        360;
  }

  // =============================================================
  // الموقع وحساب الاتجاه
  // =============================================================

  Future<void> _getLocationAndCalculate() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'يرجى تفعيل خدمة الموقع GPS',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator
                .requestPermission();

        if (permission ==
            LocationPermission.denied) {
          throw Exception(
            'تم رفض إذن الموقع',
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
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.best,
        ),
      );

      // ----------------------------------------------------------
      // Magnetic declination
      // ----------------------------------------------------------

      double declination = 0;

      try {
        final geoMag = GeoMag();

        final result =
            geoMag.calculate(
          position.latitude,
          position.longitude,
          position.altitude,
          DateTime.now(),
        );

        declination =
            result.dec;
      } catch (_) {
        declination = 0;
      }

      final target =
          _calculateBearing(
        position.latitude,
        position.longitude,
        _selectedPlace.lat,
        _selectedPlace.lng,
      );

      if (!mounted) return;

      setState(() {
        _position = position;

        _declination =
            declination;

        _targetDirection =
            target;

        _loading = false;

        _hasFirstHeading = false;

        _targetMatchCounter = 0;
      });

      await _compassSubscription?.cancel();
      await _accelerometerSubscription?.cancel();
      await _magnetometerSubscription?.cancel();

      _compassSubscription = null;
      _accelerometerSubscription = null;
      _magnetometerSubscription = null;

      _compassAvailable = false;
      _usingFallback = false;

      await _initCompass();
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

  // =============================================================
  // حساب Bearing
  //
  // من موقع المستخدم إلى المكان الهدف.
  // النتيجة بالنسبة للشمال الحقيقي.
  // =============================================================

  double _calculateBearing(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    final lat1 =
        fromLat *
        math.pi /
        180;

    final lat2 =
        toLat *
        math.pi /
        180;

    final dLng =
        (toLng - fromLng) *
        math.pi /
        180;

    final y =
        math.sin(dLng) *
        math.cos(lat2);

    final x =
        math.cos(lat1) *
            math.sin(lat2) -
        math.sin(lat1) *
            math.cos(lat2) *
            math.cos(dLng);

    var bearing =
        math.atan2(y, x) *
        180 /
        math.pi;

    if (bearing < 0) {
      bearing += 360;
    }

    return bearing;
  }

  // =============================================================
  // اختيار المكان
  // =============================================================

  void _onPlaceSelected(
    SacredPlace place,
  ) {
    if (_position == null) {
      setState(() {
        _selectedPlace = place;
      });
      return;
    }

    final bearing =
        _calculateBearing(
      _position!.latitude,
      _position!.longitude,
      place.lat,
      place.lng,
    );

    setState(() {
      _selectedPlace = place;
      _targetDirection = bearing;
      _targetMatchCounter = 0;
    });
  }

  // =============================================================
  // زاوية السهم
  // =============================================================

  double _getArrowAngle() {
    if (_targetDirection == null) {
      return 0;
    }

    var angle =
        _targetDirection! -
        _deviceHeading;

    angle %= 360;

    if (angle < 0) {
      angle += 360;
    }

    return angle;
  }

  // =============================================================
  // الفرق
  // =============================================================

  double _getAngleDifference() {
    if (_targetDirection == null) {
      return 180;
    }

    var difference =
        _targetDirection! -
        _deviceHeading;

    while (difference < -180) {
      difference += 360;
    }

    while (difference > 180) {
      difference -= 360;
    }

    return difference.abs();
  }

  // =============================================================
  // ثبات الاتجاه قبل إعلان الوصول
  // =============================================================

  bool _isFacingTarget() {
    final difference =
        _getAngleDifference();

    if (difference <= 4) {
      if (_targetMatchCounter < 6) {
        _targetMatchCounter++;
      }
    } else {
      _targetMatchCounter = 0;
    }

    return _targetMatchCounter >= 4;
  }

  // =============================================================
  // Build
  // =============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF3F1EC),
      appBar: AppBar(
        title: const Text(
          'اتجاه المراقد والأماكن المقدسة',
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
              const EdgeInsets.all(20),
          children: [
            _buildPlaceSelector(),

            const SizedBox(height: 20),

            if (_loading)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(40),
                  child:
                      CircularProgressIndicator(),
                ),
              ),

            if (_error != null)
              _buildError(),

            if (!_loading &&
                _error == null &&
                _targetDirection != null) ...[
              if (_isFacingTarget())
                _buildSuccess(),

              if (!_compassAvailable)
                _buildCompassWarning(),

              const SizedBox(height: 8),

              _buildCompass(),

              const SizedBox(height: 12),

              Text(
                _selectedPlace.name,
                textDirection:
                    TextDirection.rtl,
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 17,
                  color:
                      AppColors.primaryGreen,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _selectedPlace.subtitle,
                textDirection:
                    TextDirection.rtl,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Colors.grey[700],
                ),
              ),

              const SizedBox(height: 20),

              _buildInfoCard(),

              const SizedBox(height: 14),

              _buildLocationCard(),

              const SizedBox(height: 14),

              _buildInstructions(),
            ],
          ],
        ),
      ),
    );
  }

  // =============================================================
  // اختيار المكان
  // =============================================================

  Widget _buildPlaceSelector() {
    return Card(
      elevation: 3,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر المرقد أو المكان المقدس',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<
                SacredPlace>(
              initialValue:
                  _selectedPlace,
              isExpanded: true,
              decoration:
                  InputDecoration(
                filled: true,
                fillColor:
                    Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items:
                  sacredPlaces.map(
                (place) {
                  return DropdownMenuItem<
                      SacredPlace>(
                    value: place,
                    child: Text(
                      place.name,
                      textDirection:
                          TextDirection.rtl,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            Colors.black87,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  );
                },
              ).toList(),
              onChanged:
                  (place) {
                if (place != null) {
                  _onPlaceSelected(
                    place,
                  );
                }
              },
            ),

            const SizedBox(height: 8),

            Text(
              _selectedPlace.subtitle,
              textDirection:
                  TextDirection.rtl,
              style: const TextStyle(
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

  // =============================================================
  // Success
  // =============================================================

  Widget _buildSuccess() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFDFF5E3),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.green.shade700,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color:
                Colors.green.shade800,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'أنت متجه نحو ${_selectedPlace.name}',
              textDirection:
                  TextDirection.rtl,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.green.shade900,
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // Compass warning
  // =============================================================

  Widget _buildCompassWarning() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(12),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFFF3CD),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.orange.shade700,
        ),
      ),
      child: const Text(
        'جاري انتظار قراءة البوصلة... أبقِ الهاتف بعيدًا عن المعادن والمغناطيس ومكبرات الصوت.',
        textDirection:
            TextDirection.rtl,
        textAlign:
            TextAlign.center,
        style: TextStyle(
          color: Colors.black87,
          fontWeight:
              FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // =============================================================
  // Error
  // =============================================================

  Widget _buildError() {
    return Card(
      color:
          const Color(0xFFFFEBEE),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          children: [
            const Icon(
              Icons.location_off,
              color: Colors.red,
              size: 42,
            ),

            const SizedBox(height: 10),

            Text(
              _error!,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed:
                  _getLocationAndCalculate,
              icon:
                  const Icon(Icons.refresh),
              label:
                  const Text(
                'إعادة المحاولة',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // Compass
  // =============================================================

  Widget _buildCompass() {
    return Center(
      child: SizedBox(
        width: 330,
        height: 330,
        child: CustomPaint(
          painter:
              _CompassDialPainter(
            headingDeg:
                _deviceHeading,
          ),
          foregroundPainter:
              _CompassNeedlePainter(
            pointerAngleDeg:
                _getArrowAngle(),
            isAligned:
                _isFacingTarget(),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // Info
  // =============================================================

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly,
          children: [
            _InfoBox(
              label:
                  'اتجاه المكان',
              value:
                  '${_targetDirection!.toStringAsFixed(1)}°',
              color:
                  AppColors.primaryGreen,
            ),
            _InfoBox(
              label:
                  'اتجاه الهاتف',
              value:
                  '${_deviceHeading.toStringAsFixed(1)}°',
              color:
                  Colors.blue.shade700,
            ),
            _InfoBox(
              label:
                  'الفرق',
              value:
                  '${_getAngleDifference().toStringAsFixed(1)}°',
              color:
                  _isFacingTarget()
                      ? Colors.green.shade700
                      : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // Location information
  // =============================================================

  Widget _buildLocationCard() {
    if (_position == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'معلومات القياس',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
                color:
                    Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'موقعك: '
              '${_position!.latitude.toStringAsFixed(5)}°, '
              '${_position!.longitude.toStringAsFixed(5)}°',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'انحراف المجال المغناطيسي: '
              '${_declination.toStringAsFixed(2)}°',
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              _usingFallback
                  ? 'الحساس المستخدم: Accelerometer + Magnetometer'
                  : 'الحساس المستخدم: Compass Sensor',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                    _usingFallback
                        ? Colors.orange.shade900
                        : Colors.green.shade900,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            if (_headingAccuracy !=
                null) ...[
              const SizedBox(height: 6),
              Text(
                'دقة الحساس: '
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

  // =============================================================
  // تعليمات واضحة
  // =============================================================

  Widget _buildInstructions() {
    return Card(
      color: Colors.white,
      elevation: 2,
      child: Padding(
        padding:
            const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: const [
            Text(
              'تعليمات للحصول على أدق اتجاه',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
                color:
                    Colors.black,
              ),
            ),

            SizedBox(height: 12),

            Text(
              '1. أمسك الهاتف بشكل أفقي قدر الإمكان.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                height: 1.8,
                color:
                    Colors.black87,
              ),
            ),

            Text(
              '2. وجّه أعلى الهاتف إلى الاتجاه الذي تريد معرفة موقعه.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                height: 1.8,
                color:
                    Colors.black87,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            Text(
              '3. حرّك الهاتف ببطء وليس بسرعة.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                height: 1.8,
                color:
                    Colors.black87,
              ),
            ),

            Text(
              '4. إذا كان الاتجاه يهتز، حرّك الهاتف على شكل رقم 8 عدة مرات.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                height: 1.8,
                color:
                    Colors.black87,
              ),
            ),

            Text(
              '5. ابتعد عن السيارات والحديد والمغناطيس ومكبرات الصوت.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                height: 1.8,
                color:
                    Colors.black87,
              ),
            ),

            Text(
              '6. السهم الأخضر يشير إلى المكان المقدس المختار.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                height: 1.8,
                color:
                    Colors.black87,
              ),
            ),

            Text(
              '7. عندما يصبح الفرق قريبًا من 0° فأنت تواجه الاتجاه المطلوب.',
              textDirection:
                  TextDirection.rtl,
              style: TextStyle(
                fontSize: 13,
                height: 1.8,
                color:
                    Colors.black,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// Compass Dial
// ===================================================================

class _CompassDialPainter
    extends CustomPainter {
  final double headingDeg;

  _CompassDialPainter({
    required this.headingDeg,
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

    final radius =
        size.width / 2;

    // ---------------------------------------------------------------
    // الإطار
    // ---------------------------------------------------------------

    final bezelPaint =
        Paint()
          ..shader =
              const RadialGradient(
            colors: [
              Color(0xFFFFF6D8),
              Color(0xFFD4AF37),
              Color(0xFF765A18),
            ],
            stops: [
              0.72,
              0.91,
              1.0,
            ],
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius: radius,
            ),
          );

    canvas.drawCircle(
      center,
      radius,
      bezelPaint,
    );

    canvas.drawShadow(
      Path()
        ..addOval(
          Rect.fromCircle(
            center: center,
            radius:
                radius - 2,
          ),
        ),
      Colors.black,
      8,
      true,
    );

    // ---------------------------------------------------------------
    // الوجه
    // ---------------------------------------------------------------

    final faceRadius =
        radius - 14;

    final facePaint =
        Paint()
          ..shader =
              const RadialGradient(
            colors: [
              Colors.white,
              Color(0xFFE5E5E5),
            ],
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius:
                  faceRadius,
            ),
          );

    canvas.drawCircle(
      center,
      faceRadius,
      facePaint,
    );

    canvas.drawCircle(
      center,
      faceRadius,
      Paint()
        ..color =
            AppColors.primaryGreen
                .withOpacity(0.6)
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ---------------------------------------------------------------
    // القرص الدوار
    // ---------------------------------------------------------------

    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(
      -headingDeg *
          math.pi /
          180,
    );

    final tickRadius =
        faceRadius - 8;

    // تدريجات
    for (int deg = 0;
        deg < 360;
        deg += 5) {
      final isMajor =
          deg % 30 == 0;

      final isCardinal =
          deg % 90 == 0;

      final length =
          isCardinal
              ? 17.0
              : isMajor
                  ? 11.0
                  : 5.0;

      final angle =
          deg *
          math.pi /
          180;

      final outer =
          Offset(
        tickRadius *
            math.sin(angle),
        -tickRadius *
            math.cos(angle),
      );

      final inner =
          Offset(
        (tickRadius - length) *
            math.sin(angle),
        -(tickRadius - length) *
            math.cos(angle),
      );

      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color =
              isCardinal
                  ? (deg == 0
                      ? Colors.red.shade700
                      : Colors.black87)
                  : Colors.grey.shade600
          ..strokeWidth =
              isCardinal
                  ? 2.5
                  : isMajor
                      ? 1.6
                      : 1,
          ..strokeCap =
              StrokeCap.round,
      );
    }

    // ---------------------------------------------------------------
    // الاتجاهات
    // ---------------------------------------------------------------

    const labels = {
      0: 'شمال',
      90: 'شرق',
      180: 'جنوب',
      270: 'غرب',
    };

    labels.forEach(
      (deg, label) {
        final angle =
            deg *
            math.pi /
            180;

        final labelRadius =
            tickRadius - 30;

        final pos =
            Offset(
          labelRadius *
              math.sin(angle),
          -labelRadius *
              math.cos(angle),
        );

        final painter =
            TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: deg == 0
                  ? Colors.red.shade700
                  : Colors.black87,
              fontSize: 13,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          textDirection:
              TextDirection.rtl,
        )..layout();

        canvas.save();

        canvas.translate(
          pos.dx,
          pos.dy,
        );

        canvas.rotate(
          headingDeg *
              math.pi /
              180,
        );

        painter.paint(
          canvas,
          Offset(
            -painter.width / 2,
            -painter.height / 2,
          ),
        );

        canvas.restore();
      },
    );

    canvas.restore();

    // ---------------------------------------------------------------
    // مؤشر الهاتف الثابت
    // ---------------------------------------------------------------

    final pointer =
        Path()
          ..moveTo(
            center.dx,
            center.dy -
                radius +
                5,
          )
          ..lineTo(
            center.dx - 8,
            center.dy -
                radius +
                22,
          )
          ..lineTo(
            center.dx + 8,
            center.dy -
                radius +
                22,
          )
          ..close();

    canvas.drawPath(
      pointer,
      Paint()
        ..color =
            Colors.red.shade700,
    );

    // نقطة المركز
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color =
            Colors.white,
    );

    canvas.drawCircle(
      center,
      7,
      Paint()
        ..color =
            Colors.black87
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(
    covariant _CompassDialPainter
        oldDelegate,
  ) {
    return oldDelegate.headingDeg !=
        headingDeg;
  }
}

// ===================================================================
// Needle
// ===================================================================

class _CompassNeedlePainter
    extends CustomPainter {
  final double pointerAngleDeg;
  final bool isAligned;

  _CompassNeedlePainter({
    required this.pointerAngleDeg,
    required this.isAligned,
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

    final color =
        isAligned
            ? Colors.green.shade700
            : AppColors.primaryGreen;

    canvas.save();

    canvas.translate(
      center.dx,
      center.dy,
    );

    canvas.rotate(
      pointerAngleDeg *
          math.pi /
          180,
    );

    final length =
        size.width * 0.35;

    // ---------------------------------------------------------------
    // ظل
    // ---------------------------------------------------------------

    final shadow =
        Path()
          ..moveTo(
            0,
            -length + 3,
          )
          ..lineTo(
            11,
            7,
          )
          ..lineTo(
            -11,
            7,
          )
          ..close();

    canvas.drawPath(
      shadow,
      Paint()
        ..color =
            Colors.black
                .withOpacity(0.25)
        ..maskFilter =
            const MaskFilter.blur(
          BlurStyle.normal,
          4,
        ),
    );

    // ---------------------------------------------------------------
    // الإبرة
    // ---------------------------------------------------------------

    final needle =
        Path()
          ..moveTo(
            0,
            -length,
          )
          ..lineTo(
            10,
            7,
          )
          ..lineTo(
            -10,
            7,
          )
          ..close();

    canvas.drawPath(
      needle,
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
            -10,
            -length,
            20,
            length + 7,
          ),
        ),
    );

    canvas.drawPath(
      needle,
      Paint()
        ..color =
            Colors.white
                .withOpacity(0.6)
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ---------------------------------------------------------------
    // ذيل
    // ---------------------------------------------------------------

    final tailLength =
        size.width * 0.14;

    final tail =
        Path()
          ..moveTo(
            0,
            tailLength,
          )
          ..lineTo(
            6,
            5,
          )
          ..lineTo(
            -6,
            5,
          )
          ..close();

    canvas.drawPath(
      tail,
      Paint()
        ..color =
            AppColors.gold
                .withOpacity(0.8),
    );

    canvas.restore();

    // ---------------------------------------------------------------
    // مركز الإبرة
    // ---------------------------------------------------------------

    canvas.drawCircle(
      center,
      13,
      Paint()
        ..shader =
            const RadialGradient(
          colors: [
            Colors.white,
            Color(0xFFBDBDBD),
            Color(0xFF616161),
          ],
        ).createShader(
          Rect.fromCircle(
            center: center,
            radius: 13,
          ),
        ),
    );

    canvas.drawCircle(
      center,
      13,
      Paint()
        ..color =
            Colors.black54
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.drawCircle(
      Offset(
        center.dx - 3,
        center.dy - 3,
      ),
      3,
      Paint()
        ..color =
            Colors.white,
    );
  }

  @override
  bool shouldRepaint(
    covariant _CompassNeedlePainter
        oldDelegate,
  ) {
    return oldDelegate.pointerAngleDeg !=
            pointerAngleDeg ||
        oldDelegate.isAligned !=
            isAligned;
  }
}

// ===================================================================
// Info Box
// ===================================================================

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
          textAlign:
              TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color:
                Colors.black87,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight:
                FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
