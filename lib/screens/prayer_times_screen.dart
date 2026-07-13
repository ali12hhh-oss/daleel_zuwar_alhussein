import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import '../theme.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  Position? _position;
  PrayerTimes? _prayerTimes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getLocationAndCalculatePrayerTimes();
  }

  Future<void> _getLocationAndCalculatePrayerTimes() async {
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

      final coordinates = Coordinates(position.latitude, position.longitude);
      final params = CalculationMethod.karachi.getParameters();
      params.madhab = Madhab.hanafi;
      
      final prayerTimes = PrayerTimes.today(coordinates, params);

      setState(() {
        _position = position;
        _prayerTimes = prayerTimes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مواقيت الصلاة')),
      body: RefreshIndicator(
        onRefresh: _getLocationAndCalculatePrayerTimes,
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
                    const Text(
                      'حسب كتيب مواقيت الصلاة للسيد السيستاني دام ظله\n'
                      'يتم تحديد الموقع تلقائياً عبر GPS',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                    if (_position != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'الموقع: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}',
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
                        onPressed: _getLocationAndCalculatePrayerTimes,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),

            // ✅ أوقات الصلاة
            if (_prayerTimes != null && !_loading) ...[
              const Text(
                'أوقات الصلاة اليوم',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _PrayerTimeCard(
                name: 'الفجر',
                time: _formatTime(_prayerTimes!.fajr),
                icon: Icons.wb_twilight,
              ),
              _PrayerTimeCard(
                name: 'الشروق',
                time: _formatTime(_prayerTimes!.sunrise),
                icon: Icons.wb_sunny,
              ),
              _PrayerTimeCard(
                name: 'الظهر',
                time: _formatTime(_prayerTimes!.dhuhr),
                icon: Icons.sunny,
              ),
              _PrayerTimeCard(
                name: 'العصر',
                time: _formatTime(_prayerTimes!.asr),
                icon: Icons.sunny_snowing,
              ),
              _PrayerTimeCard(
                name: 'المغرب',
                time: _formatTime(_prayerTimes!.maghrib),
                icon: Icons.wb_twilight,
              ),
              _PrayerTimeCard(
                name: 'العشاء',
                time: _formatTime(_prayerTimes!.isha),
                icon: Icons.nights_stay,
              ),
            ],

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
                      'ملاحظات مهمة:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• الأوقات تحدد تلقائياً حسب موقعك عبر GPS\n'
                      '• يُفضل الرجوع إلى التقويم الرسمي للسيد السيستاني\n'
                      '• وقت الظهر يبدأ من زوال الشمس\n'
                      '• وقت العصر إلى أن يصير ظل كل شيء مثله ونصفه\n'
                      '• وقت المغرب من غروب الشمس إلى غيبوبة الشفق\n'
                      '• وقت العشاء من غيبوبة الشفق إلى منتصف الليل',
                      style: TextStyle(fontSize: 12, height: 1.6),
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
  final IconData icon;

  const _PrayerTimeCard({
    required this.name,
    required this.time,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
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
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'حسب التوقيت المحلي',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
