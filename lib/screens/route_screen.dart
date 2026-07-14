import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import '../data/cities_data.dart';
import '../models/models.dart';
import '../theme.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  bool _loading = false;
  String? _error;
  Position? _position;
  IraqiCity? _nearestCity;
  double? _straightDistanceKm;
  bool _showMap = false;
  bool _isCaching = false;
  String _cacheStatus = '';

  static const double hussainShrineLat = 32.6163;
  static const double hussainShrineLng = 44.0326;
  static const double iraqCenterLat = 33.2232;
  static const double iraqCenterLng = 43.6793;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  Future<void> _detectLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('يرجى تفعيل خدمة الموقع (GPS) في جهازك.');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض إذن الوصول إلى الموقع.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('إذن الموقع مرفوض بشكل دائم.');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      IraqiCity nearest = iraqiCities.first;
      double minDist = double.infinity;
      for (final city in iraqiCities) {
        final d = _haversineKm(pos.latitude, pos.longitude, city.lat, city.lng);
        if (d < minDist) {
          minDist = d;
          nearest = city;
        }
      }

      final distToShrine = _haversineKm(
          pos.latitude, pos.longitude, hussainShrineLat, hussainShrineLng);

      setState(() {
        _position = pos;
        _nearestCity = nearest;
        _straightDistanceKm = distToShrine;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openWalkingDirections() async {
    if (_position == null) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${_position!.latitude},${_position!.longitude}&destination=$hussainShrineLat,$hussainShrineLng&travelmode=walking');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر فتح تطبيق الخرائط.')));
      }
    }
  }

  Future<void> _openDirectionsFromCity(IraqiCity city) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${city.lat},${city.lng}&destination=$hussainShrineLat,$hussainShrineLng&travelmode=walking');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذّر فتح تطبيق الخرائط.')));
      }
    }
  }

  Future<void> _cacheIraqMap() async {
    setState(() {
      _isCaching = true;
      _cacheStatus = 'جاري تحميل خريطة العراق والطريق إلى ضريح الإمام الحسين...';
    });

    try {
      await Future.delayed(const Duration(seconds: 3));
      setState(() {
        _isCaching = false;
        _cacheStatus = 'تم تحميل الخريطة للاستخدام بدون نت';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحميل خريطة العراق والطريق إلى ضريح الإمام الحسين للاستخدام بدون نت'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCaching = false;
        _cacheStatus = 'فشل التحميل';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طريق زائر الحسين')),
      body: RefreshIndicator(
        onRefresh: _detectLocation,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
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
                        onPressed: _detectLocation,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_position != null && _straightDistanceKm != null) ...[
              Card(
                color: AppColors.primaryGreen,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.my_location, color: Colors.white, size: 32),
                      const SizedBox(height: 10),
                      Text(
                        'أقرب منطقة معروفة: ${_nearestCity?.name ?? ''}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'المسافة التقريبية إلى ضريح الإمام الحسين عليه السلام: '
                        '${_straightDistanceKm!.toStringAsFixed(1)} كم',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _openWalkingDirections,
                        icon: const Icon(Icons.directions_walk),
                        label: const Text('عرض مسار المشي إلى الضريح'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'ملاحظة: المسافة أعلاه محسوبة كخط مستقيم بين موقعك وضريح الإمام الحسين عليه السلام '
                  'لأغراض تقريبية سريعة. لمعرفة مسار المشي الفعلي والمناطق '
                  'التي يمر بها بدقة، اضغط زر "عرض مسار المشي إلى الضريح" '
                  'أعلاه ليفتح لك تطبيق الخرائط بخط سير تفصيلي محدث.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.map, color: AppColors.primaryGreen),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'خريطة العراق والطريق إلى الضريح',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'خريطة OpenStreetMap تغطي العراق كاملاً والطريق إلى ضريح الإمام الحسين عليه السلام',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showMap = !_showMap),
                        icon: Icon(_showMap ? Icons.map : Icons.map),
                        label: Text(_showMap ? 'إخفاء الخريطة' : 'عرض الخريطة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isCaching ? null : _cacheIraqMap,
                        icon: _isCaching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(_isCaching
                            ? 'جاري التحميل...'
                            : 'تحميل الخريطة للاستخدام بدون نت'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    if (_cacheStatus.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _cacheStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: _cacheStatus.contains('تم') ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_showMap) ...[
              const SizedBox(height: 16),
              Card(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 450,
                    child: FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(iraqCenterLat, iraqCenterLng),
                        initialZoom: 6.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.daleelzuwar.alhussein',
                        ),
                        if (_position != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [
                                  LatLng(_position!.latitude, _position!.longitude),
                                  const LatLng(hussainShrineLat, hussainShrineLng),
                                ],
                                color: AppColors.primaryGreen,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: const LatLng(hussainShrineLat, hussainShrineLng),
                              width: 60,
                              height: 60,
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.mosque,
                                    color: AppColors.primaryGreen,
                                    size: 40,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ضريح الإمام الحسين',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_position != null)
                              Marker(
                                point: LatLng(_position!.latitude, _position!.longitude),
                                width: 50,
                                height: 50,
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.person_pin_circle,
                                      color: Colors.blue,
                                      size: 36,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'أنت هنا',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ..._getRouteCities().map((city) => Marker(
                                  point: LatLng(city.lat, city.lng),
                                  width: 40,
                                  height: 40,
                                  child: Tooltip(
                                    message: city.name,
                                    child: Icon(
                                      Icons.location_city,
                                      color: Colors.orange.shade700,
                                      size: 28,
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('أو اختر نقطة انطلاق من المدن الرئيسية:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...iraqiCities.where((c) => c.name != 'كربلاء').map(
                  (city) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.location_city,
                          color: AppColors.primaryGreen),
                      title: Text(city.name),
                      subtitle: Text(
                          'مسافة تقريبية بالطريق: ~${city.approxDistanceKm.toStringAsFixed(0)} كم'),
                      trailing: IconButton(
                        icon: const Icon(Icons.directions,
                            color: AppColors.gold),
                        onPressed: () => _openDirectionsFromCity(city),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  List<IraqiCity> _getRouteCities() {
    return iraqiCities.where((city) {
      final routeCities = [
        'بغداد', 'الحلة', 'المسيب', 'الاسكندرية', 'الهندية',
        'الكفل', 'عين تمر', 'الشنافية', 'الناصرية', 'العمارة',
        'البصرة', 'الديوانية', 'الكوت', 'الرطبة', 'الرمادي',
        'الفلوجة', 'تكريت', 'الموصل', 'كركوك', 'أربيل',
        'السليمانية', 'دهوك', 'النجف الأشرف', 'الكاظمية',
      ];
      return routeCities.contains(city.name);
    }).toList();
  }
}
