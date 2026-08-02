import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../data/cities_data.dart';
import '../models/models.dart';
import '../theme.dart';
import '../services/offline_map_service.dart';

/// ✅ يمثّل خياراً واحداً من خيارات المسار (مشي أو سيارة، مع بديل رقم N)
class RouteOption {
  final double distanceKm;
  final double durationMin;
  final List<LatLng> points;
  final String profile; // 'foot' أو 'driving'

  RouteOption({
    required this.distanceKm,
    required this.durationMin,
    required this.points,
    required this.profile,
  });
}

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
  double? _roadDistanceKm;
  List<LatLng> _routePoints = [];
  bool _showMap = false;
  bool _isCaching = false;
  String _cacheStatus = '';
  bool _calculatingRoute = false;

  // ✅ كل خيارات المسار المكتشفة (مشي: عدة بدائل + سيارة: بديل واحد للمقارنة)
  List<RouteOption> _routeOptions = [];
  int _selectedRouteIndex = 0;

  int _downloadedTiles = 0;
  int _totalTiles = 0;
  double? _cachedSizeMb;

  static const double hussainShrineLat = 32.6163;
  static const double hussainShrineLng = 44.0326;
  static const double iraqCenterLat = 33.2232;
  static const double iraqCenterLng = 43.6793;

  // ✅ خريطة OpenStreetMap القياسية - تعرض أسماء الأماكن باللغة المحلية
  // (عربي للعراق) تلقائياً، بخلاف CartoDB اللي كانت تعرضها بالإنكليزي دائماً
  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  void initState() {
    super.initState();
    // ✅ ننتظر اكتمال init() فعلياً قبل قراءة حجم التخزين المؤقت، وإلا
    // getCacheSizeMb() السابقة كانت ترجع 0 دائماً (لأن مسار المجلد لم
    // يكن جاهزاً بعد)، فيبقى زر "تحميل الخريطة" ظاهراً حتى لو الخريطة
    // محمّلة فعلياً على الجهاز.
    _initMapAndCache();
    _detectLocation();
  }

  Future<void> _initMapAndCache() async {
    await OfflineMapService.init();
    await _loadCachedSize();
  }

  Future<void> _loadCachedSize() async {
    final size = await OfflineMapService.getCacheSizeMb();
    if (mounted && size > 0) {
      setState(() => _cachedSizeMb = size);
    }
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

  /// ✅ جلب كل بدائل المسار المتوفرة من OSRM لبروفايل معيّن (مشي أو سيارة)
  /// alternatives=true تجعل OSRM يعيد حتى 3 مسارات مختلفة بدل مسار واحد فقط
  Future<List<RouteOption>> _fetchRoutes({
    required double fromLat,
    required double fromLng,
    required String profile,
    int maxAlternatives = 3,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://router.project-osrm.org/route/v1/$profile/'
          '$fromLng,$fromLat;'
          '$hussainShrineLng,$hussainShrineLat'
          '?overview=full&geometries=geojson&alternatives=true&steps=false',
        ),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body);
      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        return [];
      }

      final routes = (data['routes'] as List).take(maxAlternatives).toList();
      return routes.map<RouteOption>((route) {
        final distanceKm = (route['distance'] as num).toDouble() / 1000;
        final durationMin = (route['duration'] as num).toDouble() / 60;
        final geometry = route['geometry']['coordinates'] as List;
        final points = geometry
            .map((coord) => LatLng(coord[1] as double, coord[0] as double))
            .toList();
        return RouteOption(
          distanceKm: distanceKm,
          durationMin: durationMin,
          points: points,
          profile: profile,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// ✅ حساب كل خيارات المسار (مشي + سيارة كمقارنة) وتحديد الأقصر تلقائياً
  /// ملاحظة: بيانات "مسارات المشي" بين المدن على OpenStreetMap محدودة في
  /// العراق، لذلك نضيف أيضاً مسار السيارة كخيار احتياطي/مقارنة لأن كثيراً
  /// من الزوار يمشون على جانب الطريق الرئيسي نفسه أثناء المسير
  Future<void> _calculateRoadDistance() async {
    if (_position == null) return;

    setState(() {
      _calculatingRoute = true;
      _routeOptions = [];
    });

    final options = <RouteOption>[];

    final footOptions = await _fetchRoutes(
      fromLat: _position!.latitude,
      fromLng: _position!.longitude,
      profile: 'foot',
      maxAlternatives: 3,
    );
    options.addAll(footOptions);

    final drivingOptions = await _fetchRoutes(
      fromLat: _position!.latitude,
      fromLng: _position!.longitude,
      profile: 'driving',
      maxAlternatives: 1,
    );
    options.addAll(drivingOptions);

    if (!mounted) return;

    if (options.isEmpty) {
      setState(() {
        _roadDistanceKm = _straightDistanceKm; // fallback
        _calculatingRoute = false;
      });
      return;
    }

    // ✅ تحديد المسار الأقصر تلقائياً (أفضّل مسارات المشي عند التساوي التقريبي)
    int shortestIndex = 0;
    double shortestDist = options.first.distanceKm;
    for (int i = 1; i < options.length; i++) {
      if (options[i].distanceKm < shortestDist) {
        shortestDist = options[i].distanceKm;
        shortestIndex = i;
      }
    }

    setState(() {
      _routeOptions = options;
      _selectedRouteIndex = shortestIndex;
      _roadDistanceKm = options[shortestIndex].distanceKm;
      _routePoints = options[shortestIndex].points;
      _calculatingRoute = false;
    });
  }

  void _selectRoute(int index) {
    if (index < 0 || index >= _routeOptions.length) return;
    setState(() {
      _selectedRouteIndex = index;
      _roadDistanceKm = _routeOptions[index].distanceKm;
      _routePoints = _routeOptions[index].points;
    });
  }

  /// ✅ حساب مسافة الطريق (مشياً) من أي مدينة إلى كربلاء (أقصر خيار متاح)
  Future<double> _getRoadDistanceFromCity(double lat, double lng) async {
    final footOptions = await _fetchRoutes(
      fromLat: lat,
      fromLng: lng,
      profile: 'foot',
      maxAlternatives: 3,
    );
    if (footOptions.isNotEmpty) {
      footOptions.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return footOptions.first.distanceKm;
    }
    // fallback: استخدام المسافة المستقيمة مع معامل تصحيح
    return _haversineKm(lat, lng, hussainShrineLat, hussainShrineLng) * 1.3;
  }

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

      // ✅ حساب كل خيارات المسار تلقائياً وتحديد الأقصر
      await _calculateRoadDistance();
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

  /// ✅ تحميل حقيقي: خريطة عامة للعراق كامل + تفاصيل واضحة حول كربلاء والضريح
  Future<void> _cacheIraqMap() async {
    setState(() {
      _isCaching = true;
      _downloadedTiles = 0;
      _totalTiles = 0;
      _cacheStatus = 'جاري تحضير قائمة التحميل...';
    });

    try {
      // المرحلة 1: خريطة عامة لكل العراق (مدن وطرق رئيسية)
      await OfflineMapService.downloadRegion(
        minLat: 29.0,
        maxLat: 37.4,
        minLng: 38.7,
        maxLng: 48.8,
        minZoom: 5,
        maxZoom: 10,
        onProgress: (downloaded, total, failed) {
          if (!mounted) return;
          setState(() {
            _downloadedTiles = downloaded;
            _totalTiles = total;
            _cacheStatus = 'خريطة العراق العامة: $downloaded من $total';
          });
        },
      );

      // المرحلة 2: تفاصيل واضحة حول كربلاء والضريح (مفيدة للمشي)
      await OfflineMapService.downloadRegion(
        minLat: hussainShrineLat - 0.35,
        maxLat: hussainShrineLat + 0.35,
        minLng: hussainShrineLng - 0.35,
        maxLng: hussainShrineLng + 0.35,
        minZoom: 11,
        maxZoom: 15,
        onProgress: (downloaded, total, failed) {
          if (!mounted) return;
          setState(() {
            _downloadedTiles = downloaded;
            _totalTiles = total;
            _cacheStatus = 'تفاصيل كربلاء والضريح: $downloaded من $total';
          });
        },
      );

      final sizeMb = await OfflineMapService.getCacheSizeMb();

      if (!mounted) return;
      setState(() {
        _isCaching = false;
        _cachedSizeMb = sizeMb;
        _cacheStatus =
            'تم تحميل الخريطة بنجاح (${sizeMb.toStringAsFixed(1)} م.ب) - جاهزة للاستخدام بدون إنترنت';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCaching = false;
        _cacheStatus = 'فشل التحميل، تأكد من الاتصال بالإنترنت وحاول مجدداً';
      });
    }
  }

  String _routeLabel(RouteOption option, int index) {
    final icon = option.profile == 'foot' ? '🚶' : '🚗';
    final typeLabel = option.profile == 'foot' ? 'مشي' : 'طريق رئيسي';
    // ترقيم بدائل المشي فقط (1، 2، 3...)، أما السيارة فخيار واحد فقط
    if (option.profile == 'foot') {
      final footIndex =
          _routeOptions.where((o) => o.profile == 'foot').toList().indexOf(option) + 1;
      return '$icon $typeLabel $footIndex';
    }
    return '$icon $typeLabel';
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
                        'المسافة المستقيمة: ${_straightDistanceKm!.toStringAsFixed(1)} كم',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      if (_calculatingRoute) ...[
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'جاري حساب المسارات المتاحة...',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (_roadDistanceKm != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'أقصر مسار: ${_roadDistanceKm!.toStringAsFixed(1)} كم',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '⏱️ وقت المشي التقريبي: ${(_roadDistanceKm! / 5).toStringAsFixed(0)} ساعة',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                      // ✅ قائمة كل خيارات المسار المتاحة مع مسافة كل واحد
                      if (_routeOptions.length > 1) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'اختر مساراً لعرضه على الخريطة:',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List.generate(_routeOptions.length, (i) {
                            final opt = _routeOptions[i];
                            final selected = i == _selectedRouteIndex;
                            final isShortest =
                                opt.distanceKm == _routeOptions.map((o) => o.distanceKm).reduce(min);
                            return ChoiceChip(
                              label: Text(
                                '${_routeLabel(opt, i)} • ${opt.distanceKm.toStringAsFixed(1)} كم'
                                '${isShortest ? ' ⭐' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: selected ? Colors.white : Colors.black87,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: selected,
                              selectedColor: AppColors.gold,
                              backgroundColor: Colors.white,
                              onSelected: (_) => _selectRoute(i),
                            );
                          }),
                        ),
                      ],
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
                    if (_cachedSizeMb == null) ...[
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
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'الخريطة محمّلة للاستخدام بدون نت',
                            style: TextStyle(fontSize: 13, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    if (_isCaching && _totalTiles > 0) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _downloadedTiles / _totalTiles,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${((_downloadedTiles / _totalTiles) * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                    if (_cacheStatus.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _cacheStatus,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: _cacheStatus.contains('تم')
                              ? Colors.green
                              : (_cacheStatus.contains('فشل')
                                  ? Colors.red
                                  : Colors.orange),
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
                    height: 550,
                    child: FlutterMap(
                      options: const MapOptions(
                        initialCenter: LatLng(iraqCenterLat, iraqCenterLng),
                        initialZoom: 6.5,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: _tileUrl,
                          subdomains: const [],
                          userAgentPackageName: 'com.daleelzuwar.alhussein',
                          // ملاحظة: ترويسة User-Agent الفعلية للطلبات تُرسَل
                          // من داخل OfflineFirstTileProvider (عبر NetworkImage
                          // headers)، وليس من هنا، لأن tileProvider هو من
                          // يتحكم فعلياً بجلب الصور.
                          tileProvider: OfflineFirstTileProvider(),
                        ),
                        if (_routeOptions.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              // ✅ كل المسارات البديلة تُرسم رفيعة ورمادية
                              for (int i = 0; i < _routeOptions.length; i++)
                                if (i != _selectedRouteIndex)
                                  Polyline(
                                    points: _routeOptions[i].points,
                                    color: Colors.grey.withOpacity(0.55),
                                    strokeWidth: 3,
                                  ),
                              // ✅ المسار المختار حالياً يُرسم عريضاً وملوّناً
                              Polyline(
                                points: _routeOptions[_selectedRouteIndex].points,
                                color: _routeOptions[_selectedRouteIndex].profile ==
                                        'foot'
                                    ? AppColors.primaryGreen
                                    : Colors.blueGrey,
                                strokeWidth: 5,
                                borderStrokeWidth: 2,
                                borderColor: Colors.white,
                              ),
                            ],
                          )
                        else if (_position != null)
                          PolylineLayer(
                            polylines: [
                              // fallback: خط مستقيم أثناء التحميل أو
                              // عند فشل الاتصال بخدمة التوجيه
                              Polyline(
                                points: [
                                  LatLng(_position!.latitude, _position!.longitude),
                                  const LatLng(hussainShrineLat, hussainShrineLng),
                                ],
                                color: Colors.grey,
                                strokeWidth: 3,
                                strokeCap: StrokeCap.round,
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
                  (city) => _CityDistanceTile(
                    city: city,
                    onDirections: () => _openDirectionsFromCity(city),
                    roadDistanceCalculator: _getRoadDistanceFromCity,
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
        'الكفل', 'عين تمر', 'الناصرية', 'العمارة',
        'البصرة', 'الديوانية', 'الكوت', 'الرطبة', 'الرمادي',
        'الفلوجة', 'تكريت', 'الموصل', 'كركوك', 'أربيل',
        'السليمانية', 'دهوك', 'النجف الأشرف', 'الكاظمية',
      ];
      return routeCities.contains(city.name);
    }).toList();
  }
}

/// ✅ بطاقة مدينة مع مسافة دقيقة على الطريق (أقصر خيار متاح)
class _CityDistanceTile extends StatefulWidget {
  final IraqiCity city;
  final VoidCallback onDirections;
  final Future<double> Function(double lat, double lng) roadDistanceCalculator;

  const _CityDistanceTile({
    required this.city,
    required this.onDirections,
    required this.roadDistanceCalculator,
  });

  @override
  State<_CityDistanceTile> createState() => _CityDistanceTileState();
}

class _CityDistanceTileState extends State<_CityDistanceTile> {
  double? _roadDistance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoadDistance();
  }

  Future<void> _loadRoadDistance() async {
    try {
      final distance = await widget.roadDistanceCalculator(
        widget.city.lat,
        widget.city.lng,
      );
      if (mounted) {
        setState(() {
          _roadDistance = distance;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _roadDistance = widget.city.approxDistanceKm.toDouble();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_city, color: AppColors.primaryGreen),
        title: Text(widget.city.name),
        subtitle: _loading
            ? const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('جاري حساب المسافة...', style: TextStyle(fontSize: 12)),
                ],
              )
            : Text(
                'أقصر مسافة (مشياً): ~${_roadDistance!.toStringAsFixed(0)} كم',
                style: const TextStyle(fontSize: 13),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.directions, color: AppColors.gold),
          onPressed: widget.onDirections,
        ),
      ),
    );
  }
}
