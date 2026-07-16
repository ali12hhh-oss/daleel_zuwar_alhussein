import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math' as math;
import '../theme.dart';

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

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _getLocationAndCalculate();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _showAdhanNotification(String prayerName, String time) async {
    const androidDetails = AndroidNotificationDetails(
      'adhan_channel',
      'أذان الصلاة',
      channelDescription: 'تذكير بأوقات الأذان',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('adhan'),
      playSound: true,
      enableVibration: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      prayerName.hashCode,
      'حان وقت أذان $prayerName',
      'الساعة $time',
      notificationDetails,
    );
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

      final city = _findNearestCity(position.latitude, position.longitude);
      final times = _calculateShiaPrayerTimes(
        position.latitude,
        position.longitude,
        DateTime.now(),
      );

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
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
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
      final d = _haversineKm(lat, lng, (city['lat'] as num).toDouble(), (city['lng'] as num).toDouble());
      if (d < minDist) {
        minDist = d;
        nearest = city['name'] as String;
      }
    }

    return nearest;
  }

  Map<String, DateTime> _calculateShiaPrayerTimes(double lat, double lng, DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final lngHour = lng / 15.0;
    final sunDeclination = 23.45 * math.sin((360.0 / 365.0) * (dayOfYear - 81) * math.pi / 180.0);
    final equationOfTime = 9.87 * math.sin(2 * (360.0 / 365.0) * (dayOfYear - 81) * math.pi / 180.0)
        - 7.53 * math.cos((360.0 / 365.0) * (dayOfYear - 81) * math.pi / 180.0)
        - 1.5 * math.sin((360.0 / 365.0) * (dayOfYear - 81) * math.pi / 180.0);

    final dhuhrMinutes = 4 * lngHour + equationOfTime;
    final dhuhrAdhan = DateTime(date.year, date.month, date.day, 12, 0)
        .add(Duration(minutes: dhuhrMinutes.round()));

    final hourAngleSunrise = math.acos(
        -math.tan(lat * math.pi / 180.0) * math.tan(sunDeclination * math.pi / 180.0)
    ) * 180.0 / math.pi;

    final sunrise = dhuhrAdhan.subtract(Duration(minutes: (hourAngleSunrise * 4).round()));
    final sunset = dhuhrAdhan.add(Duration(minutes: (hourAngleSunrise * 4).round()));

    final fajrAngle = 18.0;
    final fajrHourAngle = math.acos(
        (-math.sin(fajrAngle * math.pi / 180.0) +
         math.sin(lat * math.pi / 180.0) * math.sin(sunDeclination * math.pi / 180.0))
        /
        (math.cos(lat * math.pi / 180.0) * math.cos(sunDeclination * math.pi / 180.0))
    ) * 180.0 / math.pi;

    final fajrAdhan = dhuhrAdhan.subtract(
        Duration(minutes: ((hourAngleSunrise + fajrHourAngle) * 4).round()));

    final maghribAngle = 4.5;
    final maghribHourAngle = math.acos(
        (-math.sin(maghribAngle * math.pi / 180.0) +
         math.sin(lat * math.pi / 180.0) * math.sin(sunDeclination * math.pi / 180.0))
        /
        (math.cos(lat * math.pi / 180.0) * math.cos(sunDeclination * math.pi / 180.0))
    ) * 180.0 / math.pi;

    final maghribAdhan = dhuhrAdhan.add(
        Duration(minutes: ((hourAngleSunrise + maghribHourAngle) * 4).round()));

    final nextSunrise = sunrise.add(const Duration(days: 1));
    final midnight = sunset.add(
        Duration(minutes: (nextSunrise.difference(sunset).inMinutes ~/ 2)));

    return {
      'fajrAdhan': fajrAdhan,
      'dhuhrAdhan': dhuhrAdhan,
      'maghribAdhan': maghribAdhan,
      'sunrise': sunrise,
      'sunset': sunset,
      'midnight': midnight,
    };
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  String _formatTime12Hour(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:$minute $period';
  }

  bool _isCurrentPrayer(String prayerName) {
    final now = DateTime.now();
    if (_fajrAdhan == null || _dhuhrAdhan == null || _maghribAdhan == null) return false;

    switch (prayerName) {
      case 'fajr':
        return now.isAfter(_fajrAdhan!) && now.isBefore(_sunrise!);
      case 'dhuhr':
        return now.isAfter(_dhuhrAdhan!) && now.isBefore(_maghribAdhan!);
      case 'maghrib':
        return now.isAfter(_maghribAdhan!) && now.isBefore(_midnight!);
      default:
        return false;
    }
  }

  String _getNextAdhan() {
    final now = DateTime.now();
    if (_fajrAdhan == null || _dhuhrAdhan == null || _maghribAdhan == null) return '';

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
      nextAdhan = _fajrAdhan!.add(const Duration(days: 1));
      nextName = 'أذان الفجر (غداً)';
    }

    final diff = nextAdhan!.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours > 0) {
      return 'الأذان القادم: $nextName بعد $hours ساعة و $minutes دقيقة';
    } else {
      return 'الأذان القادم: $nextName بعد $minutes دقيقة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مواقيت الصلاة')),
      body: RefreshIndicator(
        onRefresh: _getLocationAndCalculate,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppColors.lightGold.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.access_time_filled, size: 48, color: AppColors.primaryGreen),
                    const SizedBox(height: 12),
                    const Text(
                      'مواقيت الأذان',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'حسب كراس توقيتات الصلاة للسيد السيستاني دام ظله',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                    const Text(
                      'للشيعة الإثني عشرية - يتحدد تلقائياً حسب موقعك',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                    if (_cityName != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'الموقع: $_cityName',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                      ),
                    ],
                    if (_position != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${_position!.latitude.toStringAsFixed(4)}°N, ${_position!.longitude.toStringAsFixed(4)}°E',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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

            if (!_loading && _error == null && _fajrAdhan != null) ...[
              Card(
                color: AppColors.primaryGreen.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: AppColors.primaryGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getNextAdhan(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (!_loading && _error == null && _fajrAdhan != null) ...[
              const Text(
                'أوقات الأذان اليوم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _AdhanCard(
                name: 'أذان الفجر',
                time: _formatTime12Hour(_fajrAdhan!),
                subtitle: 'من طلوع الفجر الصادق إلى طلوع الشمس',
                endTime: 'ينتهي: ${_formatTime12Hour(_sunrise!)}',
                icon: Icons.wb_twilight,
                isCurrent: _isCurrentPrayer('fajr'),
                color: Colors.indigo,
                onAdhan: () => _showAdhanNotification('الفجر', _formatTime12Hour(_fajrAdhan!)),
              ),

              _AdhanCard(
                name: 'أذان الظهر',
                time: _formatTime12Hour(_dhuhrAdhan!),
                subtitle: 'من زوال الشمس إلى غياب الحمرة المشرقية',
                endTime: 'ينتهي: ${_formatTime12Hour(_maghribAdhan!)}',
                icon: Icons.sunny,
                isCurrent: _isCurrentPrayer('dhuhr'),
                color: Colors.amber.shade700,
                onAdhan: () => _showAdhanNotification('الظهر', _formatTime12Hour(_dhuhrAdhan!)),
              ),

              _AdhanCard(
                name: 'أذان المغرب',
                time: _formatTime12Hour(_maghribAdhan!),
                subtitle: 'من غياب الحمرة المشرقية إلى منتصف الليل',
                endTime: 'ينتهي: ${_formatTime12Hour(_midnight!)}',
                icon: Icons.nights_stay,
                isCurrent: _isCurrentPrayer('maghrib'),
                color: Colors.deepPurple,
                onAdhan: () => _showAdhanNotification('المغرب', _formatTime12Hour(_maghribAdhan!)),
              ),
            ],

            const SizedBox(height: 16),

            Card(
              color: Colors.grey[100],
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملاحظات مهمة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• أذان الفجر: وقت صلاة الصبح من طلوع الفجر الصادق (18°) إلى طلوع الشمس',
                      style: TextStyle(fontSize: 12, height: 1.8),
                    ),
                    Text(
                      '• أذان الظهر: وقت صلاة الظهرين من الزوال إلى غياب الحمرة المشرقية',
                      style: TextStyle(fontSize: 12, height: 1.8),
                    ),
                    Text(
                      '  - يستحب تأخير صلاة العصر قليلاً',
                      style: TextStyle(fontSize: 12, height: 1.8),
                    ),
                    Text(
                      '• أذان المغرب: وقت صلاة العشائين من غياب الحمرة المشرقية إلى منتصف الليل',
                      style: TextStyle(fontSize: 12, height: 1.8),
                    ),
                    Text(
                      '  - يستحب تأخير صلاة العشاء إلى ثلث الليل',
                      style: TextStyle(fontSize: 12, height: 1.8),
                    ),
                    Text(
                      '• الأوقات تقريبية وتحدد حسب رؤية الهلال والموقع الجغرافي',
                      style: TextStyle(fontSize: 12, height: 1.8),
                    ),
                    Text(
                      '• يُفضل الرجوع إلى التقويم الرسمي للسيد السيستاني دام ظله',
                      style: TextStyle(fontSize: 12, height: 1.8),
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

class _AdhanCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? const BorderSide(color: AppColors.gold, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.gold : color,
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'الآن',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    endTime,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (onAdhan != null)
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    color: AppColors.primaryGreen,
                    tooltip: 'تشغيل صوت الأذان',
                    onPressed: onAdhan,
                  ),
                  const Text(
                    'الأذان',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
