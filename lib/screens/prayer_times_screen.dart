import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import 'rakah_counter_screen.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Position? _position;
  bool _loading = true;
  String? _error;
  String? _cityName;

  DateTime? _fajrAdhan;
  DateTime? _dhuhrAdhan;
  DateTime? _maghribAdhan;
  DateTime? _sunrise;
  DateTime? _sunset;
  DateTime? _midnight;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String _adhanSoundMode = 'sound';
  String _adhanSoundFile = 'adhan1';

  Timer? _foregroundTimer;

  String? _activeInAppPrayer;
  bool _notificationPermissionGranted = false;
  bool _exactAlarmPermissionGranted = false;

  static const int _fajrNotificationId = 1001;
  static const int _dhuhrNotificationId = 1002;
  static const int _maghribNotificationId = 1003;
  static const int _tomorrowFajrNotificationId = 1004;

  @override
  void initState() {
    super.initState();

    _foregroundTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkCurrentPrayerForForeground(),
    );

    _initApp();
  }

  @override
  void dispose() {
    _foregroundTimer?.cancel();
    super.dispose();
  }

  Future<void> _initApp() async {
    await _initNotifications();
    await _loadAdhanSettings();
    await _getLocationAndCalculate();
  }

  Future<void> _initNotifications() async {
    tz_data.initializeTimeZones();

    try {
      tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint(
          'تم الضغط على إشعار الأذان: ${response.payload}',
        );
      },
    );

    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      try {
        _notificationPermissionGranted =
            await androidImpl.requestNotificationsPermission() ?? false;
      } catch (e) {
        debugPrint('خطأ في إذن الإشعارات: $e');
      }

      try {
        _exactAlarmPermissionGranted =
            await androidImpl.requestExactAlarmsPermission() ?? false;
      } catch (e) {
        debugPrint('خطأ في إذن Exact Alarm: $e');
      }
    }
  }

  Future<void> _loadAdhanSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _adhanSoundMode = prefs.getString('adhanSoundMode') ?? 'sound';
      _adhanSoundFile = prefs.getString('adhanSoundFile') ?? 'adhan1';
    });
  }

  String get _adhanChannelId =>
      'adhan_channel_v4_${_adhanSoundMode}_$_adhanSoundFile';

  AndroidNotificationDetails _buildAdhanAndroidDetails() {
    switch (_adhanSoundMode) {
      case 'vibrate':
        return AndroidNotificationDetails(
          _adhanChannelId,
          'أذان الصلاة',
          channelDescription: 'إشعارات أوقات الصلاة - اهتزاز فقط',
          importance: Importance.max,
          priority: Priority.max,
          playSound: false,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ticker: 'حان وقت الصلاة',
        );

      case 'silent':
        return AndroidNotificationDetails(
          _adhanChannelId,
          'أذان الصلاة',
          channelDescription: 'إشعارات أوقات الصلاة - صامت',
          importance: Importance.max,
          priority: Priority.max,
          playSound: false,
          enableVibration: false,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ticker: 'حان وقت الصلاة',
        );

      case 'sound':
      default:
        return AndroidNotificationDetails(
          _adhanChannelId,
          'أذان الصلاة',
          channelDescription: 'إشعارات أوقات الأذان',
          importance: Importance.max,
          priority: Priority.max,
          sound: RawResourceAndroidNotificationSound(_adhanSoundFile),
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          ticker: 'حان وقت الصلاة',
        );
    }
  }

  tz.TZDateTime _toTZDateTime(DateTime time) {
    return tz.TZDateTime(
      tz.local,
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
      time.second,
    );
  }

  Future<void> _scheduleAdhanNotification({
    required int id,
    required String prayerName,
    required DateTime time,
  }) async {
    final now = DateTime.now();

    if (!time.isAfter(now)) {
      debugPrint(
        'تجاهل إشعار $prayerName لأن وقته أصبح في الماضي: $time',
      );
      return;
    }

    final notificationDetails = NotificationDetails(
      android: _buildAdhanAndroidDetails(),
    );

    final scheduledDate = _toTZDateTime(time);

    debugPrint(
      'جدولة $prayerName في: $scheduledDate',
    );

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        'حان وقت أذان $prayerName',
        'الساعة ${_formatTime12Hour(time)}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle,
        payload: prayerName,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint(
        'تمت جدولة إشعار $prayerName بنجاح',
      );
    } catch (e, stack) {
      debugPrint(
        'فشل جدولة إشعار $prayerName: $e',
      );
      debugPrint('$stack');
    }
  }

  Future<void> _scheduleAllAdhans() async {
    await _loadAdhanSettings();

    /*
     * نلغي الإشعارات القديمة أولاً.
     * هذا يمنع تكرار الأذان بعد تحديث الموقع أو إعادة فتح الصفحة.
     */
    await _notificationsPlugin.cancel(_fajrNotificationId);
    await _notificationsPlugin.cancel(_dhuhrNotificationId);
    await _notificationsPlugin.cancel(_maghribNotificationId);
    await _notificationsPlugin.cancel(_tomorrowFajrNotificationId);

    if (_fajrAdhan != null) {
      await _scheduleAdhanNotification(
        id: _fajrNotificationId,
        prayerName: 'الفجر',
        time: _fajrAdhan!,
      );
    }

    if (_dhuhrAdhan != null) {
      await _scheduleAdhanNotification(
        id: _dhuhrNotificationId,
        prayerName: 'الظهر',
        time: _dhuhrAdhan!,
      );
    }

    if (_maghribAdhan != null) {
      await _scheduleAdhanNotification(
        id: _maghribNotificationId,
        prayerName: 'المغرب',
        time: _maghribAdhan!,
      );
    }

    /*
     * مهم:
     * إذا فتح المستخدم التطبيق بعد المغرب، لا نريد أن ينتظر
     * إعادة فتح التطبيق في اليوم التالي حتى تتم جدولة الفجر.
     *
     * لذلك نحسب فجر اليوم التالي ونضع إشعاره مسبقاً.
     */
    if (_position != null) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      final tomorrowTimes = _calculateShiaPrayerTimes(
        _position!.latitude,
        _position!.longitude,
        tomorrow,
      );

      final tomorrowFajr = tomorrowTimes['fajrAdhan'];

      if (tomorrowFajr != null) {
        await _scheduleAdhanNotification(
          id: _tomorrowFajrNotificationId,
          prayerName: 'الفجر',
          time: tomorrowFajr,
        );
      }
    }
  }

  Future<void> _showAdhanNotification(
    String prayerName,
    String time,
  ) async {
    await _loadAdhanSettings();

    final notificationDetails = NotificationDetails(
      android: _buildAdhanAndroidDetails(),
    );

    try {
      await _notificationsPlugin.show(
        prayerName.hashCode,
        'حان وقت أذان $prayerName',
        'الساعة $time',
        notificationDetails,
        payload: prayerName,
      );
    } catch (e) {
      debugPrint('فشل الإشعار الفوري: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _adhanSoundMode == 'sound'
                ? 'تعذر تشغيل إشعار الأذان أو صوته'
                : 'تعذر تشغيل إشعار الأذان. تحقق من أذونات الإشعارات',
          ),
        ),
      );
    }
  }

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
        throw Exception('يرجى تفعيل خدمة الموقع (GPS)');
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض إذن الموقع');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'إذن الموقع مرفوض دائماً. افتح إعدادات التطبيق وفعّل الموقع.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final city = _findNearestCity(
        position.latitude,
        position.longitude,
      );

      final times = _calculateShiaPrayerTimes(
        position.latitude,
        position.longitude,
        DateTime.now(),
      );

      if (!mounted) return;

      setState(() {
        _position = position;
        _cityName = city;

        _fajrAdhan = times['fajrAdhan'];
        _dhuhrAdhan = times['dhuhrAdhan'];
        _maghribAdhan = times['maghribAdhan'];

        _sunrise = times['sunrise'];
        _sunset = times['sunset'];
        _midnight = times['midnight'];

        _loading = false;
      });

      /*
       * بعد اكتمال حساب الأوقات مباشرة:
       * أعد جدولة إشعارات اليوم والغد.
       */
      await _scheduleAllAdhans();

      debugPrint(
        'تم تحديث المواقيت والإشعارات للموقع: $city',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _checkCurrentPrayerForForeground() {
    if (!mounted ||
        _fajrAdhan == null ||
        _dhuhrAdhan == null ||
        _maghribAdhan == null) {
      return;
    }

    final now = DateTime.now();

    String? prayer;
    DateTime? prayerTime;

    if (_isSameMinute(now, _fajrAdhan!)) {
      prayer = 'الفجر';
      prayerTime = _fajrAdhan;
    } else if (_isSameMinute(now, _dhuhrAdhan!)) {
      prayer = 'الظهر';
      prayerTime = _dhuhrAdhan;
    } else if (_isSameMinute(now, _maghribAdhan!)) {
      prayer = 'المغرب';
      prayerTime = _maghribAdhan;
    }

    if (prayer == null || prayerTime == null) {
      return;
    }

    /*
     * منع ظهور التنبيه الداخلي عشرات المرات خلال نفس الدقيقة.
     */
    if (_activeInAppPrayer == prayer) {
      return;
    }

    setState(() {
      _activeInAppPrayer = prayer;
    });

    _showInAppPrayerBanner(
      prayer,
      _formatTime12Hour(prayerTime),
    );

    Future.delayed(
      const Duration(minutes: 1, seconds: 5),
      () {
        if (!mounted) return;

        if (_activeInAppPrayer == prayer) {
          setState(() {
            _activeInAppPrayer = null;
          });
        }
      },
    );
  }

  bool _isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }

  void _showInAppPrayerBanner(
    String prayer,
    String time,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        backgroundColor: AppColors.primaryGreen,
        leading: const Icon(
          Icons.notifications_active,
          color: AppColors.lightGold,
          size: 30,
        ),
        content: Text(
          'حان الآن وقت أذان $prayer\nالساعة $time',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .hideCurrentMaterialBanner();
            },
            child: const Text(
              'حسنًا',
              style: TextStyle(
                color: AppColors.lightGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _findNearestCity(double lat, double lng) {
    final cities = [
      {'name': 'بغداد', 'lat': 33.3152, 'lng': 44.3661},
      {'name': 'كربلاء المقدسة', 'lat': 32.6160, 'lng': 44.0240},
      {'name': 'النجف الأشرف', 'lat': 32.0000, 'lng': 44.3333},
      {'name': 'البصرة', 'lat': 30.5156, 'lng': 47.7804},
      {'name': 'الموصل', 'lat': 36.3566, 'lng': 43.1642},
      {'name': 'أربيل', 'lat': 36.1911, 'lng': 44.0092},
      {'name': 'السليمانية', 'lat': 35.5575, 'lng': 45.4350},
      {'name': 'الناصرية', 'lat': 31.0489, 'lng': 46.2637},
      {'name': 'الكوت', 'lat': 32.5093, 'lng': 45.8182},
      {'name': 'الحلة', 'lat': 32.4637, 'lng': 44.4194},
      {'name': 'الديوانية', 'lat': 31.9924, 'lng': 44.9242},
      {'name': 'العمارة', 'lat': 31.8333, 'lng': 47.1500},
      {'name': 'الرمادي', 'lat': 33.4206, 'lng': 43.3078},
      {'name': 'تكريت', 'lat': 34.5969, 'lng': 43.6781},
      {'name': 'كركوك', 'lat': 35.4669, 'lng': 44.3923},
      {'name': 'دهوك', 'lat': 36.8679, 'lng': 42.9884},
      {'name': 'سامراء', 'lat': 34.1983, 'lng': 43.8746},
      {'name': 'الكاظمية المقدسة', 'lat': 33.3797, 'lng': 44.3369},
      {'name': 'سوق الشيوخ', 'lat': 31.1833, 'lng': 46.2667},
      {'name': 'السماوة', 'lat': 31.3326, 'lng': 45.2944},
      {'name': 'الشطرة', 'lat': 31.4167, 'lng': 46.1667},
      {'name': 'الزبير', 'lat': 30.3833, 'lng': 47.7167},
      {'name': 'الفلوجة', 'lat': 33.3490, 'lng': 43.7830},
      {'name': 'الفاو', 'lat': 29.9667, 'lng': 48.4667},
      {'name': 'بعقوبة', 'lat': 33.7447, 'lng': 44.6436},
      {'name': 'خانقين', 'lat': 34.3500, 'lng': 45.3833},
      {'name': 'مندلي', 'lat': 33.7500, 'lng': 45.5500},
      {'name': 'الحمدانية', 'lat': 33.7667, 'lng': 44.2167},
      {'name': 'المسيب', 'lat': 32.5667, 'lng': 44.3500},
      {'name': 'الإسكندرية', 'lat': 32.2000, 'lng': 44.6167},
      {'name': 'عين تمر', 'lat': 32.0667, 'lng': 43.4833},
      {'name': 'الشنافية', 'lat': 31.5833, 'lng': 44.6500},
      {'name': 'القائم', 'lat': 34.3667, 'lng': 41.0833},
      {'name': 'عنة', 'lat': 34.3667, 'lng': 41.9833},
      {'name': 'حديثة', 'lat': 34.1333, 'lng': 42.3833},
      {'name': 'السويرة', 'lat': 33.9167, 'lng': 44.7833},
      {'name': 'الجلولاء', 'lat': 34.2833, 'lng': 45.4833},
      {'name': 'قره تبة', 'lat': 35.3500, 'lng': 45.4333},
    ];

    String nearest = 'موقعك الحالي';
    double minDist = double.infinity;

    for (final city in cities) {
      final d = _haversineKm(
        lat,
        lng,
        (city['lat'] as num).toDouble(),
        (city['lng'] as num).toDouble(),
      );

      if (d < minDist) {
        minDist = d;
        nearest = city['name'] as String;
      }
    }

    return nearest;
  }

  Map<String, DateTime> _calculateShiaPrayerTimes(
    double lat,
    double lng,
    DateTime date,
  ) {
    /*
     * الحساب الحالي محفوظ كما هو:
     *
     * الفجر = الفجر الصادق بزاوية 18°
     * الظهر = الزوال
     * المغرب = غياب الحمرة المشرقية تقريبياً
     * منتصف الليل = نصف المدة بين الغروب والفجر التالي
     */

    const fajrAngle = 18.0;
    const maghribAngle = 4.5;
    const sunriseSunsetAngle = 0.833;

    final sunToday = _sunPosition(
      _julianDate(
        date.year,
        date.month,
        date.day,
      ),
    );

    final dhuhrUtc =
        12.0 -
        (lng / 15.0) -
        sunToday.equationOfTime;

    final fajrT = _sunAngleTime(
      fajrAngle,
      lat,
      sunToday.declination,
    );

    final riseSetT = _sunAngleTime(
      sunriseSunsetAngle,
      lat,
      sunToday.declination,
    );

    final maghribT = _sunAngleTime(
      maghribAngle,
      lat,
      sunToday.declination,
    );

    final fajrAdhan = _utcHoursToLocalDateTime(
      date,
      dhuhrUtc - fajrT,
    );

    final dhuhrAdhan = _utcHoursToLocalDateTime(
      date,
      dhuhrUtc,
    );

    final sunrise = _utcHoursToLocalDateTime(
      date,
      dhuhrUtc - riseSetT,
    );

    final sunset = _utcHoursToLocalDateTime(
      date,
      dhuhrUtc + riseSetT,
    );

    final maghribAdhan = _utcHoursToLocalDateTime(
      date,
      dhuhrUtc + maghribT,
    );

    final tomorrow = date.add(
      const Duration(days: 1),
    );

    final sunTomorrow = _sunPosition(
      _julianDate(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
      ),
    );

    final dhuhrTomorrowUtc =
        12.0 -
        (lng / 15.0) -
        sunTomorrow.equationOfTime;

    final fajrTomorrowT = _sunAngleTime(
      fajrAngle,
      lat,
      sunTomorrow.declination,
    );

    final nextFajr = _utcHoursToLocalDateTime(
      tomorrow,
      dhuhrTomorrowUtc - fajrTomorrowT,
    );

    final midnight = sunset.add(
      Duration(
        minutes:
            nextFajr.difference(sunset).inMinutes ~/ 2,
      ),
    );

    return {
      'fajrAdhan': fajrAdhan,
      'dhuhrAdhan': dhuhrAdhan,
      'maghribAdhan': maghribAdhan,
      'sunrise': sunrise,
      'sunset': sunset,
      'midnight': midnight,
    };
  }

  double _julianDate(
    int year,
    int month,
    int day,
  ) {
    var y = year;
    var m = month;

    if (m <= 2) {
      y -= 1;
      m += 12;
    }

    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();

    return (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;
  }

  _SunPosition _sunPosition(double jd) {
    final d = jd - 2451545.0;

    final g = _fixAngle(
      357.529 + 0.98560028 * d,
    );

    final q = _fixAngle(
      280.459 + 0.98564736 * d,
    );

    final l = _fixAngle(
      q +
          1.915 *
              math.sin(
                g * math.pi / 180.0,
              ) +
          0.020 *
              math.sin(
                2 * g * math.pi / 180.0,
              ),
    );

    final e = 23.439 - 0.00000036 * d;

    var ra = math.atan2(
          math.cos(
            e * math.pi / 180.0,
          ) *
              math.sin(
                l * math.pi / 180.0,
              ),
          math.cos(
            l * math.pi / 180.0,
          ),
        ) *
        180.0 /
        math.pi /
        15.0;

    ra = _fixHour(ra);

    final eqt = q / 15.0 - ra;

    final decl =
        math.asin(
          math.sin(
                e * math.pi / 180.0,
              ) *
              math.sin(
                l * math.pi / 180.0,
              ),
        ) *
        180.0 /
        math.pi;

    return _SunPosition(
      decl,
      eqt,
    );
  }

  double _fixAngle(double a) {
    final r = a % 360.0;
    return r < 0 ? r + 360.0 : r;
  }

  double _fixHour(double h) {
    final r = h % 24.0;
    return r < 0 ? r + 24.0 : r;
  }

  double _sunAngleTime(
    double angle,
    double lat,
    double decl,
  ) {
    final numerator =
        -math.sin(
              angle * math.pi / 180.0,
            ) -
            math.sin(
              lat * math.pi / 180.0,
            ) *
                math.sin(
                  decl * math.pi / 180.0,
                );

    final denominator =
        math.cos(
              lat * math.pi / 180.0,
            ) *
            math.cos(
              decl * math.pi / 180.0,
            );

    final ratio =
        (numerator / denominator).clamp(
      -1.0,
      1.0,
    );

    return math.acos(ratio) *
        180.0 /
        math.pi /
        15.0;
  }

  DateTime _utcHoursToLocalDateTime(
    DateTime date,
    double hours,
  ) {
    final totalMinutes =
        (hours * 60).round();

    return DateTime.utc(
      date.year,
      date.month,
      date.day,
    )
        .add(
          Duration(minutes: totalMinutes),
        )
        .toLocal();
  }

  double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371.0;

    final dLat =
        (lat2 - lat1) *
            math.pi /
            180.0;

    final dLon =
        (lon2 - lon1) *
            math.pi /
            180.0;

    final a =
        math.sin(dLat / 2) *
                math.sin(dLat / 2) +
            math.cos(
                  lat1 *
                      math.pi /
                      180.0,
                ) *
                math.cos(
                  lat2 *
                      math.pi /
                      180.0,
                ) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

    final c =
        2 *
            math.atan2(
              math.sqrt(a),
              math.sqrt(1 - a),
            );

    return r * c;
  }

  String _formatTime12Hour(
    DateTime time,
  ) {
    final hour = time.hour;

    final minute =
        time.minute.toString().padLeft(
              2,
              '0',
            );

    final period =
        hour >= 12 ? 'م' : 'ص';

    final hour12 =
        hour == 0
            ? 12
            : hour > 12
                ? hour - 12
                : hour;

    return '$hour12:$minute $period';
  }

  bool _isCurrentPrayer(
    String prayerName,
  ) {
    final now = DateTime.now();

    if (_fajrAdhan == null ||
        _dhuhrAdhan == null ||
        _maghribAdhan == null ||
        _sunrise == null ||
        _sunset == null ||
        _midnight == null) {
      return false;
    }

    switch (prayerName) {
      case 'fajr':
        return now.isAfter(_fajrAdhan!) &&
            now.isBefore(_sunrise!);

      case 'dhuhr':
        return now.isAfter(_dhuhrAdhan!) &&
            now.isBefore(_sunset!);

      case 'maghrib':
        return now.isAfter(_maghribAdhan!) &&
            now.isBefore(_midnight!);

      default:
        return false;
    }
  }

  String _getNextAdhan() {
    final now = DateTime.now();

    if (_fajrAdhan == null ||
        _dhuhrAdhan == null ||
        _maghribAdhan == null) {
      return '';
    }

    DateTime? nextAdhan;
    String nextName = '';

    if (now.isBefore(_fajrAdhan!)) {
      nextAdhan = _fajrAdhan;
      nextName = 'أذان الفجر';
    } else if (now.isBefore(_dhuhrAdhan!)) {
      nextAdhan = _dhuhrAdhan;
      nextName = 'أذان الظهر';
    } else if (now.isBefore(_maghribAdhan!)) {
      nextAdhan = _maghribAdhan;
      nextName = 'أذان المغرب';
    } else {
      nextAdhan = _fajrAdhan!.add(
        const Duration(days: 1),
      );
      nextName = 'أذان الفجر (غداً)';
    }

    if (nextAdhan == null) {
      return '';
    }

    final diff = nextAdhan.difference(now);

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours > 0) {
      return 'الأذان القادم: $nextName بعد $hours ساعة و $minutes دقيقة';
    }

    return 'الأذان القادم: $nextName بعد $minutes دقيقة';
  }

  Future<void> _testNotification() async {
    await _showAdhanNotification(
      'اختبار',
      _formatTime12Hour(DateTime.now()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مواقيت الصلاة'),
        actions: [
          IconButton(
            tooltip: 'اختبار الإشعار',
            icon: const Icon(
              Icons.notifications_active_outlined,
            ),
            onPressed: _testNotification,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _getLocationAndCalculate,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /*
             * بطاقة المواقيت المختصرة.
             */
            Card(
              elevation: 5,
              shadowColor:
                  AppColors.primaryGreen.withOpacity(0.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              color: AppColors.lightGold.withOpacity(0.25),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time_filled,
                          size: 30,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'مواقيت الأذان',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    if (_cityName != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 20,
                            color: AppColors.lightGold,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'الموقع: $_cityName',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.lightGold,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (_position != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${_position!.latitude.toStringAsFixed(4)}°N, '
                        '${_position!.longitude.toStringAsFixed(4)}°E',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            /*
             * زر عداد الركعات أصبح هنا مباشرة أسفل البطاقة.
             */
            const SizedBox(height: 14),

            Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryGreen,
                    Color(0xFF0B2A21),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RakahCounterScreen(
                        fajrAdhan: _fajrAdhan,
                        sunrise: _sunrise,
                        dhuhrAdhan: _dhuhrAdhan,
                        maghribAdhan: _maghribAdhan,
                        midnight: _midnight,
                      ),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 17,
                      horizontal: 20,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.self_improvement,
                          size: 34,
                          color: AppColors.lightGold,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'عداد الركعات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'عدّ السجدات والركعات أثناء الصلاة',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_back_ios_new,
                          color: AppColors.lightGold,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child:
                      CircularProgressIndicator(),
                ),
              ),

            if (_error != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed:
                            _getLocationAndCalculate,
                        child:
                            const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),

            if (!_loading &&
                _error == null &&
                _fajrAdhan != null) ...[
              const SizedBox(height: 16),

              Card(
                color: AppColors.primaryGreen
                    .withOpacity(0.10),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timer,
                        color:
                            AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getNextAdhan(),
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'أوقات الأذان اليوم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _AdhanCard(
                name: 'أذان الفجر',
                time:
                    _formatTime12Hour(
                  _fajrAdhan!,
                ),
                subtitle:
                    'من طلوع الفجر الصادق إلى طلوع الشمس',
                endTime:
                    'ينتهي: ${_formatTime12Hour(_sunrise!)}',
                icon:
                    Icons.wb_twilight,
                isCurrent:
                    _isCurrentPrayer('fajr'),
                color: Colors.indigo,
                onAdhan: () =>
                    _showAdhanNotification(
                  'الفجر',
                  _formatTime12Hour(
                    _fajrAdhan!,
                  ),
                ),
              ),

              _AdhanCard(
                name: 'أذان الظهر',
                time:
                    _formatTime12Hour(
                  _dhuhrAdhan!,
                ),
                subtitle:
                    'من الزوال إلى مغيب قرص الشمس',
                endTime:
                    'ينتهي: ${_formatTime12Hour(_sunset!)}',
                icon: Icons.sunny,
                isCurrent:
                    _isCurrentPrayer('dhuhr'),
                color:
                    Colors.amber.shade700,
                onAdhan: () =>
                    _showAdhanNotification(
                  'الظهر',
                  _formatTime12Hour(
                    _dhuhrAdhan!,
                  ),
                ),
              ),

              _AdhanCard(
                name: 'أذان المغرب',
                time:
                    _formatTime12Hour(
                  _maghribAdhan!,
                ),
                subtitle:
                    'من غياب الحمرة المشرقية إلى منتصف الليل',
                endTime:
                    'ينتهي: ${_formatTime12Hour(_midnight!)}',
                icon:
                    Icons.nights_stay,
                isCurrent:
                    _isCurrentPrayer('maghrib'),
                color:
                    Colors.deepPurple,
                onAdhan: () =>
                    _showAdhanNotification(
                  'المغرب',
                  _formatTime12Hour(
                    _maghribAdhan!,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Card(
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceEvenly,
                    children: [
                      _SunTimeInfo(
                        icon: Icons
                            .wb_sunny_outlined,
                        label: 'الشروق',
                        time:
                            _formatTime12Hour(
                          _sunrise!,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      _SunTimeInfo(
                        icon:
                            Icons.wb_twilight,
                        label: 'الغروب',
                        time:
                            _formatTime12Hour(
                          _sunset!,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      _SunTimeInfo(
                        icon: Icons
                            .bedtime_outlined,
                        label: 'منتصف الليل',
                        time:
                            _formatTime12Hour(
                          _midnight!,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            Card(
              child: const Padding(
                padding:
                    EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملاحظات مهمة:',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• أذان الفجر: وقت صلاة الصبح من طلوع الفجر الصادق (18°) إلى طلوع الشمس',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.8,
                      ),
                    ),
                    Text(
                      '• أذان الظهر: وقت صلاة الظهرين من الزوال إلى مغيب قرص الشمس',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.8,
                      ),
                    ),
                    Text(
                      '  - يستحب تأخير صلاة العصر قليلاً',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.8,
                      ),
                    ),
                    Text(
                      '• أذان المغرب: وقت صلاة العشائين من غياب الحمرة المشرقية إلى منتصف الليل',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.8,
                      ),
                    ),
                    Text(
                      '  - يستحب تأخير صلاة العشاء إلى ثلث الليل',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.8,
                      ),
                    ),
                    Text(
                      '• منتصف الليل الشرعي = منتصف المدة بين غروب الشمس وطلوع الفجر الصادق لليوم التالي',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.8,
                      ),
                    ),
                    Text(
                      '• الأوقات تقريبية وتحدد حسب الموقع الجغرافي',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SunPosition {
  final double declination;
  final double equationOfTime;

  const _SunPosition(
    this.declination,
    this.equationOfTime,
  );
}

class _SunTimeInfo
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;

  const _SunTimeInfo({
    required this.icon,
    required this.label,
    required this.time,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 22,
          color:
              AppColors.primaryGreen,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontSize: 14,
            fontWeight:
                FontWeight.bold,
            color:
                AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }
}

class _AdhanCard
    extends StatelessWidget {
  final String name;
  final String time;
  final String subtitle;
  final String endTime;
  final IconData icon;
  final bool isCurrent;
  final Color color;
  final VoidCallback? onAdhan;

  const _AdhanCard({
    required this.name,
    required this.time,
    required this.subtitle,
    required this.endTime,
    required this.icon,
    required this.isCurrent,
    required this.color,
    this.onAdhan,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      elevation: isCurrent ? 5 : 2,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
        side: isCurrent
            ? const BorderSide(
                color:
                    AppColors.gold,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration:
                  BoxDecoration(
                color: isCurrent
                    ? AppColors.gold
                    : color,
                borderRadius:
                    BorderRadius.circular(
                  25,
                ),
              ),
              alignment:
                  Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(
                          width: 8,
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                AppColors
                                    .gold,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                          child:
                              const Text(
                            'الآن',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 11,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    time,
                    style:
                        const TextStyle(
                      fontSize: 26,
                      fontWeight:
                          FontWeight.bold,
                      color: AppColors
                          .primaryGreen,
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    subtitle,
                    style:
                        TextStyle(
                      fontSize: 11,
                      color:
                          Colors.grey[600],
                    ),
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    endTime,
                    style:
                        TextStyle(
                      fontSize: 11,
                      color:
                          Colors.red[400],
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (onAdhan != null)
              Column(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.volume_up,
                    ),
                    color: AppColors
                        .primaryGreen,
                    tooltip:
                        'تشغيل صوت الأذان',
                    onPressed:
                        onAdhan,
                  ),
                  const Text(
                    'الأذان',
                    style:
                        TextStyle(
                      fontSize: 10,
                      color:
                          Colors.grey,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
