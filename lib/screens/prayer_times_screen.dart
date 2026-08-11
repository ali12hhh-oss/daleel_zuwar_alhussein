import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

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

  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await _initNotifications();
    await _getLocationAndCalculate();
  }

  // ============================================================
  // الإشعارات
  // ============================================================

  Future<void> _initNotifications() async {
    try {
      tz_data.initializeTimeZones();

      // التطبيق يستهدف العراق حاليًا.
      tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
      );

      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (android != null) {
        // Android 13+
        await android.requestNotificationsPermission();

        // Android 12+
        final canScheduleExact =
            await android.canScheduleExactNotifications();

        if (canScheduleExact == false) {
          await android.requestExactAlarmsPermission();
        }
      }

      _notificationsInitialized = true;

      debugPrint('✅ تم تهيئة نظام الإشعارات بنجاح');
    } catch (e, stackTrace) {
      _notificationsInitialized = false;

      debugPrint('❌ فشل تهيئة الإشعارات: $e');
      debugPrint('$stackTrace');
    }
  }

  tz.TZDateTime _toTZDateTime(DateTime dt) {
    return tz.TZDateTime(
      tz.local,
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
    );
  }

  Future<void> _loadAdhanSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final soundMode = prefs.getString('adhanSoundMode') ?? 'sound';
    final soundFile = prefs.getString('adhanSoundFile') ?? 'adhan1';

    if (!mounted) {
      _adhanSoundMode = soundMode;
      _adhanSoundFile = soundFile;
      return;
    }

    setState(() {
      _adhanSoundMode = soundMode;
      _adhanSoundFile = soundFile;
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
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
          ticker: 'حان وقت الصلاة',
        );

      case 'silent':
        return AndroidNotificationDetails(
          _adhanChannelId,
          'أذان الصلاة',
          channelDescription: 'إشعارات أوقات الصلاة - صامت',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
          ticker: 'حان وقت الصلاة',
        );

      case 'sound':
      default:
        return AndroidNotificationDetails(
          _adhanChannelId,
          'أذان الصلاة',
          channelDescription: 'إشعارات أوقات الصلاة مع صوت الأذان',
          importance: Importance.max,
          priority: Priority.max,
          sound: RawResourceAndroidNotificationSound(
            _adhanSoundFile,
          ),
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
          ticker: 'حان وقت الصلاة',
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );
    }
  }

  Future<void> _scheduleAdhanNotification(
    int id,
    String prayerName,
    DateTime time,
  ) async {
    if (!_notificationsInitialized) {
      debugPrint(
        '⚠️ الإشعارات غير مهيأة، لم يتم جدولة $prayerName',
      );
      return;
    }

    final now = DateTime.now();

    if (!time.isAfter(now)) {
      debugPrint(
        '⏭️ تم تجاهل أذان $prayerName لأن وقته أصبح في الماضي: $time',
      );
      return;
    }

    final scheduledDate = _toTZDateTime(time);

    if (!scheduledDate.isAfter(tz.TZDateTime.now(tz.local))) {
      debugPrint(
        '⏭️ وقت أذان $prayerName أصبح في الماضي',
      );
      return;
    }

    final notificationDetails = NotificationDetails(
      android: _buildAdhanAndroidDetails(),
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
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'adhan_$prayerName',
      );

      debugPrint(
        '✅ تمت جدولة أذان $prayerName في $scheduledDate',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ فشل جدولة أذان $prayerName: $e',
      );
      debugPrint('$stackTrace');
    }
  }

  Future<void> _scheduleAllAdhans() async {
    if (!_notificationsInitialized) {
      debugPrint(
        '⚠️ الإشعارات غير مهيأة، لن تتم الجدولة',
      );
      return;
    }

    if (_position == null) {
      debugPrint(
        '⚠️ لا يوجد موقع GPS، لن تتم جدولة الأذان',
      );
      return;
    }

    try {
      await _loadAdhanSettings();

      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (android != null) {
        final notificationsEnabled =
            await android.areNotificationsEnabled();

        if (notificationsEnabled == false) {
          debugPrint(
            '❌ إشعارات التطبيق غير مفعلة',
          );
          return;
        }

        final exactAllowed =
            await android.canScheduleExactNotifications();

        if (exactAllowed == false) {
          debugPrint(
            '⚠️ Exact Alarm غير مفعّل، سيتم طلب الإذن',
          );

          await android.requestExactAlarmsPermission();

          final checkAgain =
              await android.canScheduleExactNotifications();

          if (checkAgain != true) {
            debugPrint(
              '❌ لم يتم منح صلاحية Exact Alarm',
            );
            return;
          }
        }
      }

      for (int day = 0; day < 7; day++) {
        for (int prayer = 0; prayer < 3; prayer++) {
          final id = 7000 + (day * 10) + prayer;

          try {
            await _notificationsPlugin.cancel(id);
          } catch (_) {}
        }
      }

      final baseDate = DateTime.now();

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final date = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
        ).add(
          Duration(days: dayOffset),
        );

        final times = _calculateShiaPrayerTimes(
          _position!.latitude,
          _position!.longitude,
          date,
        );

        final fajr = times['fajrAdhan'];
        final dhuhr = times['dhuhrAdhan'];
        final maghrib = times['maghribAdhan'];

        final baseId = 7000 + (dayOffset * 10);

        if (fajr != null) {
          await _scheduleAdhanNotification(
            baseId,
            'الفجر',
            fajr,
          );
        }

        if (dhuhr != null) {
          await _scheduleAdhanNotification(
            baseId + 1,
            'الظهر',
            dhuhr,
          );
        }

        if (maghrib != null) {
          await _scheduleAdhanNotification(
            baseId + 2,
            'المغرب',
            maghrib,
          );
        }
      }

      final pending =
          await _notificationsPlugin.pendingNotificationRequests();

      debugPrint(
        '📅 عدد إشعارات الأذان المجدولة: ${pending.length}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ خطأ في جدولة الأذان: $e',
      );
      debugPrint('$stackTrace');
    }
  }

  Future<void> _showAdhanNotification(
    String prayerName,
    String time,
  ) async {
    try {
      if (!_notificationsInitialized) {
        await _initNotifications();
      }

      await _loadAdhanSettings();

      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (android != null) {
        final enabled =
            await android.areNotificationsEnabled();

        if (enabled == false) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'إشعارات التطبيق غير مفعلة من إعدادات الهاتف',
                ),
              ),
            );
          }
          return;
        }
      }

      final notificationDetails = NotificationDetails(
        android: _buildAdhanAndroidDetails(),
      );

      await _notificationsPlugin.show(
        9900 + prayerName.hashCode.abs() % 100,
        'حان وقت أذان $prayerName',
        'الساعة $time',
        notificationDetails,
        payload: 'manual_adhan_$prayerName',
      );

      debugPrint(
        '✅ تم عرض إشعار اختبار الأذان: $prayerName',
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ فشل عرض إشعار الأذان: $e',
      );
      debugPrint('$stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذر عرض إشعار الأذان: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // الموقع والحساب
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
          'يرجى تفعيل خدمة الموقع (GPS)',
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

      if (permission ==
          LocationPermission.deniedForever) {
        throw Exception(
          'إذن الموقع مرفوض دائماً، يرجى تفعيله من إعدادات الهاتف',
        );
      }

      final position =
          await Geolocator.getCurrentPosition(
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

      try {
        await _scheduleAllAdhans();
      } catch (e, stackTrace) {
        debugPrint(
          '❌ تعذرت جدولة إشعارات الأذان: $e',
        );
        debugPrint('$stackTrace');
      }
    } catch (e, stackTrace) {
      debugPrint(
        '❌ خطأ في تحديد الموقع والحساب: $e',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _error =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
        _loading = false;
      });
    }
  }

  String _findNearestCity(
    double lat,
    double lng,
  ) {
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
      {'name': 'السويرة', 'lat': 33.9167, 'lng': 44.7830},
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

  // ============================================================
  // حساب المواقيت
  // ============================================================

  Map<String, DateTime> _calculateShiaPrayerTimes(
    double lat,
    double lng,
    DateTime date,
  ) {
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

    final fajrAdhan =
        _utcHoursToLocalDateTime(
      date,
      dhuhrUtc - fajrT,
    );

    final dhuhrAdhan =
        _utcHoursToLocalDateTime(
      date,
      dhuhrUtc,
    );

    final sunrise =
        _utcHoursToLocalDateTime(
      date,
      dhuhrUtc - riseSetT,
    );

    final sunset =
        _utcHoursToLocalDateTime(
      date,
      dhuhrUtc + riseSetT,
    );

    final maghribAdhan =
        _utcHoursToLocalDateTime(
      date,
      dhuhrUtc + maghribT,
    );

    final tomorrow =
        date.add(const Duration(days: 1));

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

    final fajrTomorrowT =
        _sunAngleTime(
      fajrAngle,
      lat,
      sunTomorrow.declination,
    );

    final nextFajr =
        _utcHoursToLocalDateTime(
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

    final b =
        2 -
        a +
        (a / 4).floor();

    return
        (365.25 * (y + 4716)).floor() +
        (30.6001 * (m + 1)).floor() +
        day +
        b -
        1524.5;
  }

  _SunPosition _sunPosition(
    double jd,
  ) {
    final d =
        jd - 2451545.0;

    final g = _fixAngle(
      357.529 +
      0.98560028 * d,
    );

    final q = _fixAngle(
      280.459 +
      0.98564736 * d,
    );

    final l = _fixAngle(
      q +
      1.915 *
          math.sin(
            g * math.pi / 180.0,
          ) +
      0.020 *
          math.sin(
            2 *
                g *
                math.pi /
                180.0,
          ),
    );

    final e =
        23.439 -
        0.00000036 * d;

    var ra =
        math.atan2(
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

    final eqt =
        q / 15.0 -
        ra;

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

  double _fixAngle(
    double a,
  ) {
    final r =
        a % 360.0;

    return r < 0
        ? r + 360.0
        : r;
  }

  double _fixHour(
    double h,
  ) {
    final r =
        h % 24.0;

    return r < 0
        ? r + 24.0
        : r;
  }

  double _sunAngleTime(
    double angle,
    double lat,
    double decl,
  ) {
    final numerator =
        -math.sin(
              angle *
                  math.pi /
                  180.0,
            ) -
        math.sin(
              lat *
                  math.pi /
                  180.0,
            ) *
            math.sin(
              decl *
                  math.pi /
                  180.0,
            );

    final denominator =
        math.cos(
              lat *
                  math.pi /
                  180.0,
            ) *
            math.cos(
              decl *
                  math.pi /
                  180.0,
            );

    final ratio =
        (numerator /
                denominator)
            .clamp(
      -1.0,
      1.0,
    );

    return
        math.acos(
              ratio,
            ) *
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
          Duration(
            minutes:
                totalMinutes,
          ),
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
        math.sin(
              dLat / 2,
            ) *
            math.sin(
              dLat / 2,
            ) +
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
            math.sin(
              dLon / 2,
            ) *
            math.sin(
              dLon / 2,
            );

    final c =
        2 *
        math.atan2(
          math.sqrt(a),
          math.sqrt(
            1 - a,
          ),
        );

    return r * c;
  }

  String _formatTime12Hour(
    DateTime time,
  ) {
    final hour =
        time.hour;

    final minute =
        time.minute
            .toString()
            .padLeft(
              2,
              '0',
            );

    final period =
        hour >= 12
            ? 'م'
            : 'ص';

    final hour12 =
        hour == 0
            ? 12
            : (hour > 12
                ? hour - 12
                : hour);

    return '$hour12:$minute $period';
  }

  // ============================================================
  // الأذان القادم
  // ============================================================

  bool _isCurrentPrayer(
    String prayerName,
  ) {
    final now =
        DateTime.now();

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
        return now.isAfter(
              _fajrAdhan!,
            ) &&
            now.isBefore(
              _sunrise!,
            );

      case 'dhuhr':
        return now.isAfter(
              _dhuhrAdhan!,
            ) &&
            now.isBefore(
              _sunset!,
            );

      case 'maghrib':
        return now.isAfter(
              _maghribAdhan!,
            ) &&
            now.isBefore(
              _midnight!,
            );

      default:
        return false;
    }
  }

  String _getNextAdhan() {
    final now =
        DateTime.now();

    if (_fajrAdhan == null ||
        _dhuhrAdhan == null ||
        _maghribAdhan == null) {
      return '';
    }

    DateTime nextAdhan;
    String nextName;

    if (now.isBefore(
      _fajrAdhan!,
    )) {
      nextAdhan =
          _fajrAdhan!;
      nextName =
          'أذان الفجر';
    } else if (now.isBefore(
      _dhuhrAdhan!,
    )) {
      nextAdhan =
          _dhuhrAdhan!;
      nextName =
          'أذان الظهر';
    } else if (now.isBefore(
      _maghribAdhan!,
    )) {
      nextAdhan =
          _maghribAdhan!;
      nextName =
          'أذان المغرب';
    } else {
      if (_position != null) {
        final tomorrow =
            DateTime.now().add(
          const Duration(days: 1),
        );

        final tomorrowTimes =
            _calculateShiaPrayerTimes(
          _position!.latitude,
          _position!.longitude,
          tomorrow,
        );

        nextAdhan =
            tomorrowTimes['fajrAdhan'] ??
                _fajrAdhan!.add(
                  const Duration(days: 1),
                );
      } else {
        nextAdhan =
            _fajrAdhan!.add(
          const Duration(days: 1),
        );
      }

      nextName =
          'أذان الفجر (غداً)';
    }

    final diff =
        nextAdhan.difference(now);

    final totalMinutes =
        diff.inMinutes;

    if (totalMinutes <= 0) {
      return 'الأذان القادم: $nextName قريباً';
    }

    final hours =
        totalMinutes ~/ 60;

    final minutes =
        totalMinutes % 60;

    if (hours > 0) {
      return
          'الأذان القادم: $nextName بعد $hours ساعة و $minutes دقيقة';
    }

    return
        'الأذان القادم: $nextName بعد $minutes دقيقة';
  }

  // ============================================================
  // الواجهة
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مواقيت الصلاة',
        ),
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
            12,
            16,
            24,
          ),
          children: [
            _buildLocationHeader(),

            const SizedBox(
              height: 12,
            ),

            if (_loading)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(
                    40,
                  ),
                  child:
                      CircularProgressIndicator(),
                ),
              ),

            if (_error != null)
              Card(
                color:
                    Colors.red.shade50,
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons
                            .location_off,
                        size: 42,
                        color:
                            Colors.red.shade400,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        _error!,
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _getLocationAndCalculate,
                        icon:
                            const Icon(
                          Icons.refresh,
                        ),
                        label:
                            const Text(
                          'إعادة المحاولة',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (!_loading &&
                _error == null &&
                _fajrAdhan != null) ...[
              _buildRakahCounterButton(),

              const SizedBox(
                height: 14,
              ),

              _buildNextAdhanCard(),

              const SizedBox(
                height: 20,
              ),

              const Text(
                'أوقات الأذان اليوم',
                style:
                    TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

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
                    _isCurrentPrayer(
                  'fajr',
                ),
                color:
                    Colors.indigo,
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
                    'من زوال الشمس إلى مغيب قرص الشمس',
                endTime:
                    'ينتهي: ${_formatTime12Hour(_sunset!)}',
                icon:
                    Icons.sunny,
                isCurrent:
                    _isCurrentPrayer(
                  'dhuhr',
                ),
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
                    _isCurrentPrayer(
                  'maghrib',
                ),
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

              const SizedBox(
                height: 6,
              ),

              _buildSunTimesCard(),
            ],

            const SizedBox(
              height: 18,
            ),

            _buildNotesCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // بطاقة مواقيت الأذان + الموقع
  // ============================================================

  Widget _buildLocationHeader() {
    return Card(
      elevation: 3,
      margin: EdgeInsets.zero,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: Container(
        decoration:
            BoxDecoration(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          gradient:
              LinearGradient(
            begin:
                Alignment.topRight,
            end:
                Alignment.bottomLeft,
            colors: [
              AppColors.lightGold
                  .withOpacity(
                0.28,
              ),
              AppColors.lightGold
                  .withOpacity(
                0.10,
              ),
            ],
          ),
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    AppColors.primaryGreen,
                boxShadow: [
                  BoxShadow(
                    color: AppColors
                        .primaryGreen
                        .withOpacity(
                      0.25,
                    ),
                    blurRadius: 10,
                    offset:
                        const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),
              child:
                  const Icon(
                Icons.access_time_filled,
                color:
                    Colors.white,
                size: 25,
              ),
            ),

            const SizedBox(
              width: 13,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  const Text(
                    'مواقيت الأذان',
                    style:
                        TextStyle(
                      fontSize: 19,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  if (_cityName != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 17,
                          color:
                              Colors.black87,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Flexible(
                          child: Text(
                            _cityName!,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.bold,
                              color:
                                  Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'جاري تحديد موقعك...',
                      style:
                          TextStyle(
                        fontSize: 13,
                        color:
                            Colors.black54,
                      ),
                    ),

                  if (_position != null) ...[
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      '${_position!.latitude.toStringAsFixed(4)}°N  •  ${_position!.longitude.toStringAsFixed(4)}°E',
                      style:
                          const TextStyle(
                        fontSize: 10.5,
                        color:
                            Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            IconButton(
              tooltip:
                  'تحديث الموقع والمواقيت',
              onPressed:
                  _loading
                      ? null
                      : _getLocationAndCalculate,
              icon:
                  const Icon(
                Icons.my_location,
              ),
              color:
                  AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // زر عداد الركعات
  // ============================================================

  Widget _buildRakahCounterButton() {
    return Material(
      color:
          Colors.transparent,
      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RakahCounterScreen(
                fajrAdhan:
                    _fajrAdhan,
                sunrise:
                    _sunrise,
                dhuhrAdhan:
                    _dhuhrAdhan,
                maghribAdhan:
                    _maghribAdhan,
                midnight:
                    _midnight,
              ),
            ),
          );
        },
        child:
            Container(
          width:
              double.infinity,
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 17,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            gradient:
                const LinearGradient(
              begin:
                  Alignment.topRight,
              end:
                  Alignment.bottomLeft,
              colors: [
                Color(
                  0xFF17634C,
                ),
                Color(
                  0xFF0B2A21,
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black
                        .withOpacity(
                  0.22,
                ),
                blurRadius: 15,
                offset:
                    const Offset(
                  0,
                  7,
                ),
              ),
              BoxShadow(
                color:
                    AppColors.lightGold
                        .withOpacity(
                  0.16,
                ),
                blurRadius: 18,
                spreadRadius:
                    -4,
              ),
            ],
            border:
                Border.all(
              color:
                  AppColors.lightGold
                      .withOpacity(
                0.55,
              ),
              width: 1.2,
            ),
          ),
          child:
              Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color:
                      AppColors.lightGold
                          .withOpacity(
                    0.14,
                  ),
                  border:
                      Border.all(
                    color:
                        AppColors.lightGold
                            .withOpacity(
                      0.45,
                    ),
                  ),
                ),
                child:
                    const Icon(
                  Icons.self_improvement,
                  color:
                      AppColors.lightGold,
                  size: 31,
                ),
              ),

              const SizedBox(
                width: 15,
              ),

              const Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'عداد الركعات',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(
                      height: 4,
                    ),
                    Text(
                      'عداد السجدات والركعات أثناء الصلاة',
                      style:
                          TextStyle(
                        color:
                            Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color:
                      AppColors.lightGold,
                ),
                child:
                    const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color:
                      Color(
                    0xFF0B2A21,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // بطاقة الأذان القادم
  // ============================================================

  Widget _buildNextAdhanCard() {
    return Card(
      margin:
          EdgeInsets.zero,
      elevation: 1,
      color:
          AppColors.primaryGreen
              .withOpacity(
        0.08,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        side:
            BorderSide(
          color: AppColors
              .primaryGreen
              .withOpacity(
            0.15,
          ),
        ),
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        child:
            Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    AppColors.primaryGreen
                        .withOpacity(
                  0.12,
                ),
              ),
              child:
                  const Icon(
                Icons.timer_outlined,
                color:
                    AppColors.primaryGreen,
              ),
            ),
            const SizedBox(
              width: 11,
            ),
            Expanded(
              child:
                  Text(
                _getNextAdhan(),
                style:
                    const TextStyle(
                  fontSize: 13,
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
    );
  }

  // ============================================================
  // الشروق والغروب ومنتصف الليل
  // ============================================================

  Widget _buildSunTimesCard() {
    return Card(
      margin:
          EdgeInsets.zero,
      elevation: 1,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 14,
        ),
        child:
            Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceEvenly,
          children: [
            _SunTimeInfo(
              icon:
                  Icons.wb_sunny_outlined,
              label:
                  'الشروق',
              time:
                  _formatTime12Hour(
                _sunrise!,
              ),
            ),

            Container(
              width: 1,
              height: 42,
              color:
                  Colors.grey[300],
            ),

            _SunTimeInfo(
              icon:
                  Icons.wb_twilight,
              label:
                  'الغروب',
              time:
                  _formatTime12Hour(
                _sunset!,
              ),
            ),

            Container(
              width: 1,
              height: 42,
              color:
                  Colors.grey[300],
            ),

            _SunTimeInfo(
              icon:
                  Icons.bedtime_outlined,
              label:
                  'منتصف الليل',
              time:
                  _formatTime12Hour(
                _midnight!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // الملاحظات
  // ============================================================

  Widget _buildNotesCard() {
    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child:
          const Padding(
        padding:
            EdgeInsets.all(
          15,
        ),
        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Text(
              'ملاحظات مهمة:',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Text(
              '• أذان الفجر: وقت صلاة الصبح من طلوع الفجر الصادق (18°) إلى طلوع الشمس',
              style:
                  TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            Text(
              '• أذان الظهر: وقت صلاة الظهرين من الزوال إلى مغيب قرص الشمس',
              style:
                  TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            Text(
              '  - يستحب تأخير صلاة العصر قليلاً',
              style:
                  TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            Text(
              '• أذان المغرب: وقت صلاة العشائين من غياب الحمرة المشرقية إلى منتصف الليل',
              style:
                  TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            Text(
              '  - يستحب تأخير صلاة العشاء إلى ثلث الليل',
              style:
                  TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            Text(
              '• منتصف الليل الشرعي = منتصف المدة بين غروب الشمس وطلوع الفجر الصادق لليوم التالي',
              style:
                  TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            Text(
              '• الأوقات تقريبية وتحدد حسب رؤية الهلال والموقع الجغرافي',
              style:
                  TextStyle(
                fontSize: 12,
                height: 1.8,
              ),
            ),
            Text(
              '• يُفضل الرجوع إلى التقويم الرسمي للسيد السيستاني دام ظله',
              style:
                  TextStyle(
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
// بيانات الشمس
// ================================================================

class _SunPosition {
  final double declination;
  final double equationOfTime;

  const _SunPosition(
    this.declination,
    this.equationOfTime,
  );
}

// ================================================================
// معلومات الشروق والغروب
// ================================================================

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
        const SizedBox(
          height: 4,
        ),
        Text(
          label,
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
          time,
          style:
              const TextStyle(
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

// ================================================================
// بطاقة الأذان
// ================================================================

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
      elevation:
          isCurrent ? 4 : 1,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        side: isCurrent
            ? const BorderSide(
                color:
                    AppColors.gold,
                width: 2,
              )
            : BorderSide.none,
      ),
      child:
          Padding(
        padding:
            const EdgeInsets.all(
          14,
        ),
        child:
            Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration:
                  BoxDecoration(
                color:
                    isCurrent
                        ? AppColors.gold
                        : color,
                shape:
                    BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black
                            .withOpacity(
                      0.12,
                    ),
                    blurRadius:
                        7,
                    offset:
                        const Offset(
                      0,
                      3,
                    ),
                  ),
                ],
              ),
              alignment:
                  Alignment.center,
              child:
                  Icon(
                icon,
                color:
                    Colors.white,
                size: 25,
              ),
            ),

            const SizedBox(
              width: 13,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child:
                            Text(
                          name,
                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),

                      if (isCurrent) ...[
                        const SizedBox(
                          width: 7,
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                7,
                            vertical:
                                2,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                AppColors
                                    .gold,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child:
                              const Text(
                            'الآن',
                            style:
                                TextStyle(
                              color:
                                  Colors.white,
                              fontSize:
                                  10,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    time,
                    style:
                        const TextStyle(
                      fontSize: 25,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppColors
                              .primaryGreen,
                    ),
                  ),

                  const SizedBox(
                    height: 1,
                  ),

                  Text(
                    subtitle,
                    style:
                        TextStyle(
                      fontSize: 10.5,
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
                      fontSize: 10.5,
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
                  Material(
                    color:
                        AppColors
                            .primaryGreen
                            .withOpacity(
                      0.10,
                    ),
                    shape:
                        const CircleBorder(),
                    child:
                        IconButton(
                      icon:
                          const Icon(
                        Icons
                            .volume_up_rounded,
                      ),
                      color:
                          AppColors
                              .primaryGreen,
                      tooltip:
                          'اختبار إشعار وصوت الأذان',
                      onPressed:
                          onAdhan,
                    ),
                  ),
                  const SizedBox(
                    height: 1,
                  ),
                  const Text(
                    'اختبار',
                    style:
                        TextStyle(
                      fontSize: 9,
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
