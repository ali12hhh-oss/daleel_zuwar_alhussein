import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  // ✅ أوقات الصلاة المحسوبة
  DateTime? _fajr;
  DateTime? _sunrise;
  DateTime? _dhuhr;
  DateTime? _sunset;
  DateTime? _midnight;

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

      // ✅ تحديد أقرب مدينة
      final city = _findNearestCity(position.latitude, position.longitude);

      // ✅ حساب أوقات الصلاة
      final times = _calculateShiaPrayerTimes(
        position.latitude,
        position.longitude,
        DateTime.now(),
      );

      setState(() {
        _position = position;
        _cityName = city;
        _fajr = times['fajr'];
        _sunrise = times['sunrise'];
        _dhuhr = times['dhuhr'];
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

  /// ✅ تحديد أقرب مدينة عراقية
  String _findNearestCity(double lat, double lng) {
    final cities = [
      {'name': 'بغداد', 'lat': 33.3152, 'lng': 44.3661},
      {'name': 'كربلاء المقدسة', 'lat': 32.6160, 'lng': 44.0240},
      {'name': 'النجف الأشرف', 'lat': 31.9924, 'lng': 44.3140},
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
      {'name': 'كاظمية', 'lat': 33.3797, 'lng': 44.3369},
      {'name': 'سوق الشيوخ', 'lat': 31.1833, 'lng': 46.2667},
      {'name': 'السماوة', 'lat': 31.3326, 'lng': 45.2944},
      {'name': 'الشطرة', 'lat': 31.4167, 'lng': 46.1667},
      {'name': 'الزبير', 'lat': 30.3833, 'lng': 47.7167},
      {'name': 'الفلوجة', 'lat': 33.3490, 'lng': 43.7830},
      {'name': 'الفاو', 'lat': 29.9667, 'lng': 48.4667},
      {'name': 'الخالص', 'lat': 33.8167, 'lng': 44.5333},
      {'name': 'العزيزية', 'lat': 32.9167, 'lng': 45.0667},
      {'name': 'بلد', 'lat': 34.0167, 'lng': 44.1500},
      {'name': 'بعقوبة', 'lat': 33.7447, 'lng': 44.6436},
      {'name': 'خانقين', 'lat': 34.3500, 'lng': 45.3833},
      {'name': 'مندلي', 'lat': 33.7500, 'lng': 45.5500},
      {'name': 'الكاظمية', 'lat': 33.3797, 'lng': 44.3369},
      {'name': 'الكاظمية المقدسة', 'lat': 33.3797, 'lng': 44.3369},
      {'name': 'العشق', 'lat': 33.4500, 'lng': 44.3667},
      {'name': 'الحمدانية', 'lat': 33.7667, 'lng': 44.2167},
      {'name': 'الطارمية', 'lat': 33.6667, 'lng': 44.2167},
      {'name': 'المسيب', 'lat': 32.5667, 'lng': 44.3500},
      {'name': 'الاسكندرية', 'lat': 32.2000, 'lng': 44.6167},
      {'name': 'الحيدرية', 'lat': 32.5333, 'lng': 44.4833},
      {'name': 'الحر', 'lat': 32.4667, 'lng': 44.4167},
      {'name': 'الهندية', 'lat': 32.5500, 'lng': 44.2333},
      {'name': 'القاسم', 'lat': 32.5833, 'lng': 44.0833},
      {'name': 'الكفل', 'lat': 32.4167, 'lng': 44.4167},
      {'name': 'عين تمر', 'lat': 32.0667, 'lng': 43.4833},
      {'name': 'الشنافية', 'lat': 31.5833, 'lng': 44.6500},
      {'name': 'الرطبة', 'lat': 33.0333, 'lng': 40.2833},
      {'name': 'القائم', 'lat': 34.3667, 'lng': 41.0833},
      {'name': 'عنة', 'lat': 34.3667, 'lng': 41.9833},
      {'name': 'حديثة', 'lat': 34.1333, 'lng': 42.3833},
      {'name': 'الحقلانية', 'lat': 36.7167, 'lng': 42.1167},
      {'name': 'السويرا', 'lat': 33.9167, 'lng': 44.7833},
      {'name': 'الجلولاء', 'lat': 34.2833, 'lng': 45.4833},
      {'name': 'قره تبه', 'lat': 35.3500, 'lng': 45.4333},
    ];

    String nearest = 'موقعك الحالي';
    double minDist = double.infinity;

    for (final city in cities) {
      final d = _haversineKm(lat, lng, city['lat']!, city['lng']!);
      if (d < minDist) {
        minDist = d;
        nearest = city['name']!;
      }
    }

    return nearest;
  }

  /// ✅ حساب أوقات الصلاة للشيعة (حسب كراس السيد السيستاني)
  Map<String, DateTime> _calculateShiaPrayerTimes(double lat, double lng, DateTime date) {
    // اليوم من السنة
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;

    // زاوية الميل الشمسي
    final sunDeclination = 23.45 * math.sin((360.0 / 365.0) * (dayOfYear - 81) * math.pi / 180.0);

    // زمن الظهر (الزوال)
    final lngHour = lng / 15.0;
    final equationOfTime = 9.87 * math.sin(2 * (360.0 / 365.0) * (dayOfYear - 81) * math.pi / 180.0)
        - 7.53 * math.cos((360.0 / 365.0) * (dayOfYear - 81) * math.pi / 180.0)
        - 1.5 * math.sin((360.0 / 365.0) * (dayOfYear - 81) * math.pi / 180.0);

    final dhuhrMinutes = 4 * lngHour + equationOfTime;
    final dhuhr = DateTime(date.year, date.month, date.day, 12, 0).add(Duration(minutes: dhuhrMinutes.round()));

    // زمن الشروق والغروب
    final hourAngle = math.acos(-math.tan(lat * math.pi / 180.0) * math.tan(sunDeclination * math.pi / 180.0)) * 180.0 / math.pi;
    final sunrise = dhuhr.subtract(Duration(minutes: (hourAngle * 4).round()));
    final sunset = dhuhr.add(Duration(minutes: (hourAngle * 4).round()));

    // الفجر (18 درجة قبل الشروق للشيعة)
    final fajrAngle = 18.0;
    final fajrHourAngle = math.acos(
        (-math.sin(fajrAngle * math.pi / 180.0) + math.sin(lat * math.pi / 180.0) * math.sin(sunDeclination * math.pi / 180.0))
            / (math.cos(lat * math.pi / 180.0) * math.cos(sunDeclination * math.pi / 180.0))
    ) * 180.0 / math.pi;
    final fajr = dhuhr.subtract(Duration(minutes: ((hourAngle + fajrHourAngle) * 4).round()));

    // منتصف الليل
    final midnight = sunset.add(Duration(minutes: ((sunrise.add(Duration(days: 1)).difference(sunset)).inMinutes ~/ 2)));

    return {
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
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

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// ✅ التحقق مما إذا كان الوقت الحالي ضمن وقت الصلاة
  bool _isCurrentPrayer(String prayerName) {
    final now = DateTime.now();
    if (_fajr == null || _dhuhr == null || _sunset == null) return false;

    switch (prayerName) {
      case 'fajr':
        return now.isAfter(_fajr!) && now.isBefore(_sunrise!);
      case 'dhuhr':
        return now.isAfter(_dhuhr!) && now.isBefore(_sunset!);
      case 'maghrib':
        return now.isAfter(_sunset!) && now.isBefore(_midnight!);
      default:
        return false;
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
            // ✅ بطاقة المعلومات
            Card(
              color: AppColors.lightGold.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.access_time_filled, size: 48, color: AppColors.primaryGreen),
                    const SizedBox(height: 12),
                    const Text(
                      'مواقيت الصلاة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'حسب كراس توقيتات الصلاة للسيد السيستاني دام ظله\n'
                      'للشيعة الإثني عشرية - الوقت يتحدد تلقائياً حسب موقعك',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
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

            // ✅ أوقات الصلاة للشيعة
            if (!_loading && _error == null && _fajr != null) ...[
              const Text(
                'أوقات الصلاة اليوم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // ✅ صلاة الصبح
              _PrayerTimeCard(
                name: 'صلاة الصبح',
                time: _formatTime(_fajr!),
                subtitle: 'من طلوع الفجر الصادق إلى طلوع الشمس',
                icon: Icons.wb_twilight,
                isCurrent: _isCurrentPrayer('fajr'),
                color: Colors.indigo,
              ),

              // ✅ الشروق (انتهاء وقت الصبح)
              _PrayerTimeCard(
                name: 'الشروق',
                time: _formatTime(_sunrise!),
                subtitle: 'انتهاء وقت صلاة الصبح',
                icon: Icons.wb_sunny,
                isCurrent: false,
                color: Colors.orange,
              ),

              // ✅ صلاة الظهرين (الظهر + العصر)
              _PrayerTimeCard(
                name: 'صلاة الظهرين',
                time: _formatTime(_dhuhr!),
                subtitle: 'من زوال الشمس إلى الغروب (الظهر + العصر)',
                icon: Icons.sunny,
                isCurrent: _isCurrentPrayer('dhuhr'),
                color: Colors.amber.shade700,
              ),

              // ✅ الغروب
              _PrayerTimeCard(
                name: 'الغروب',
                time: _formatTime(_sunset!),
                subtitle: 'انتهاء وقت صلاة الظهرين',
                icon: Icons.wb_twilight,
                isCurrent: false,
                color: Colors.deepOrange,
              ),

              // ✅ صلاة العشائين (المغرب + العشاء)
              _PrayerTimeCard(
                name: 'صلاة العشائين',
                time: _formatTime(_sunset!),
                subtitle: 'من الغروب إلى منتصف الليل (المغرب + العشاء)',
                icon: Icons.nights_stay,
                isCurrent: _isCurrentPrayer('maghrib'),
                color: Colors.deepPurple,
              ),

              // ✅ منتصف الليل
              _PrayerTimeCard(
                name: 'منتصف الليل',
                time: _formatTime(_midnight!),
                subtitle: 'انتهاء وقت صلاة العشائين',
                icon: Icons.bedtime,
                isCurrent: false,
                color: Colors.blueGrey,
              ),
            ],

            const SizedBox(height: 16),

            // ✅ ملاحظات مهمة للشيعة
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
                      '• صلاة الصبح: وقت واحد من طلوع الفجر الصادق إلى طلوع الشمس\n'
                      '• صلاة الظهرين: وقت واحد من زوال الشمس (الظهر) إلى الغروب\n'
                      '  - يستحب تأخير العصر قليلاً\n'
                      '• صلاة العشائين: وقت واحد من الغروب إلى منتصف الليل\n'
                      '  - يستحب تأخير العشاء إلى ثلث الليل\n'
                      '• الأوقات تقريبية وتحدد حسب رؤية الهلال والموقع الجغرافي\n'
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

// ✅ بطاقة وقت الصلاة
class _PrayerTimeCard extends StatelessWidget {
  final String name;
  final String time;
  final String subtitle;
  final IconData icon;
  final bool isCurrent;
  final Color color;

  const _PrayerTimeCard({
    required this.name,
    required this.time,
    required this.subtitle,
    required this.icon,
    required this.isCurrent,
    required this.color,
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
                      fontSize: 22,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
