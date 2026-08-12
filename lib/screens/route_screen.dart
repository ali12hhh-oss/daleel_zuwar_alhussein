import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../data/cities_data.dart';
import '../models/models.dart';
import '../theme.dart';
import '../services/offline_map_service.dart';

/// ===============================================================
/// RouteOption
/// ===============================================================

class RouteOption {
  final double distanceKm;
  final double durationMin;
  final List<LatLng> points;

  /// اسم المسار
  final String name;

  /// هل هو المسار الأقصر؟
  final bool isMain;

  /// مصدر المسار:
  /// online / offline
  final String source;

  RouteOption({
    required this.distanceKm,
    required this.durationMin,
    required this.points,
    required this.name,
    required this.isMain,
    required this.source,
  });
}

/// ===============================================================
/// الوجهات المقدسة
/// ===============================================================

class SacredPlace {
  final String name;
  final String subtitle;
  final double lat;
  final double lng;
  final IconData icon;

  const SacredPlace({
    required this.name,
    required this.subtitle,
    required this.lat,
    required this.lng,
    required this.icon,
  });
}

/// يمكنك إضافة أي مرقد أو مكان مقدس هنا.
/// ===============================================================

const List<SacredPlace> sacredPlaces = [
  SacredPlace(
    name: 'ضريح الإمام الحسين (ع)',
    subtitle: 'كربلاء المقدسة - العراق',
    lat: 32.6163,
    lng: 44.0326,
    icon: Icons.mosque,
  ),

  SacredPlace(
    name: 'ضريح الإمام العباس (ع)',
    subtitle: 'كربلاء المقدسة - العراق',
    lat: 32.6167,
    lng: 44.0336,
    icon: Icons.mosque,
  ),

  SacredPlace(
    name: 'مسجد الكوفة',
    subtitle: 'النجف - العراق',
    lat: 32.0280,
    lng: 44.4010,
    icon: Icons.mosque,
  ),

  SacredPlace(
    name: 'مسجد السهلة',
    subtitle: 'الكوفة - العراق',
    lat: 32.0157,
    lng: 44.3758,
    icon: Icons.mosque,
  ),

  SacredPlace(
    name: 'ضريح الإمام علي (ع)',
    subtitle: 'النجف الأشرف - العراق',
    lat: 32.0006,
    lng: 44.3240,
    icon: Icons.mosque,
  ),

  SacredPlace(
    name: 'مقبرة وادي السلام',
    subtitle: 'النجف الأشرف - العراق',
    lat: 32.0078,
    lng: 44.3097,
    icon: Icons.location_city,
  ),
];

/// ===============================================================
/// RouteScreen
/// ===============================================================

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  SacredPlace? _selectedPlace;

  /// false = صفحة الاختيار
  /// true = صفحة الخرائط
  bool _showMapsPage = false;

  @override
  Widget build(BuildContext context) {
    if (_showMapsPage && _selectedPlace != null) {
      return _MapsPage(
        place: _selectedPlace!,
        onBack: () {
          setState(() {
            _showMapsPage = false;
          });
        },
      );
    }

    return _PlacesPage(
      onPlaceSelected: (place) {
        setState(() {
          _selectedPlace = place;
          _showMapsPage = true;
        });
      },
    );
  }
}

/// ===============================================================
/// صفحة الأماكن المقدسة
/// ===============================================================

class _PlacesPage extends StatelessWidget {
  final ValueChanged<SacredPlace> onPlaceSelected;

  const _PlacesPage({
    required this.onPlaceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'المراقد والأماكن المقدسة',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.map,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(height: 10),
                Text(
                  'اختر المرقد أو المكان المقدس',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  'بعد الاختيار ستنتقل إلى صفحة الخرائط لاختيار الخريطة الأونلاين أو الأوفلاين.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          ...sacredPlaces.map(
            (place) => _SacredPlaceCard(
              place: place,
              onTap: () => onPlaceSelected(place),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// بطاقة المكان
/// ===============================================================

class _SacredPlaceCard extends StatelessWidget {
  final SacredPlace place;
  final VoidCallback onTap;

  const _SacredPlaceCard({
    required this.place,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  place.icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      place.subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// صفحة الخرائط
/// ===============================================================

class _MapsPage extends StatefulWidget {
  final SacredPlace place;
  final VoidCallback onBack;

  const _MapsPage({
    required this.place,
    required this.onBack,
  });

  @override
  State<_MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<_MapsPage> {
  Position? _position;

  bool _loadingLocation = true;
  bool _loadingRoutes = false;

  String? _error;

  List<RouteOption> _routes = [];

  int _selectedRoute = 0;

  bool _onlineMode = true;

  double? _straightDistance;

  final MapController _mapController = MapController();

  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await OfflineMapService.init();
    await _getLocation();
  }

  /// ===============================================================
  /// تحديد الموقع
  /// متوافق مع geolocator 11.1.0
  /// ===============================================================

  Future<void> _getLocation() async {
    setState(() {
      _loadingLocation = true;
      _error = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
        throw Exception(
          'يرجى تفعيل خدمة الموقع GPS من إعدادات الجهاز.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'تم رفض إذن الوصول إلى الموقع.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'إذن الموقع مرفوض بشكل دائم. فعّل الإذن من إعدادات التطبيق.',
        );
      }

      /// لا تستخدم locationSettings هنا.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final distance = _haversineKm(
        position.latitude,
        position.longitude,
        widget.place.lat,
        widget.place.lng,
      );

      if (!mounted) return;

      setState(() {
        _position = position;
        _straightDistance = distance;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingLocation = false;
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  /// ===============================================================
  /// Haversine
  /// ===============================================================

  double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const radius = 6371.0;

    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(
      sqrt(a),
      sqrt(1 - a),
    );

    return radius * c;
  }

  double _deg2rad(double degree) {
    return degree * pi / 180;
  }

  /// ===============================================================
  /// تشغيل المحرك
  /// ===============================================================

  Future<void> _calculateRoutes() async {
    if (_position == null) {
      await _getLocation();
    }

    if (_position == null) return;

    if (_onlineMode) {
      await _calculateOnlineRoutes();
    } else {
      await _calculateOfflineRoutes();
    }
  }

  /// ===============================================================
  /// محرك أونلاين
  ///
  /// OSRM
  /// ===============================================================

  Future<void> _calculateOnlineRoutes() async {
    setState(() {
      _loadingRoutes = true;
      _routes = [];
      _error = null;
    });

    try {
      final fromLat = _position!.latitude;
      final fromLng = _position!.longitude;

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$fromLng,$fromLat;'
        '${widget.place.lng},${widget.place.lat}'
        '?overview=full'
        '&geometries=geojson'
        '&alternatives=true'
        '&steps=true',
      );

      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) {
        throw Exception(
          'تعذر الاتصال بمحرك حساب الطرق.',
        );
      }

      final data = jsonDecode(response.body);

      if (data['code'] != 'Ok') {
        throw Exception(
          'لم يتم العثور على طريق مناسب لهذه الوجهة.',
        );
      }

      final rawRoutes = data['routes'] as List;

      if (rawRoutes.isEmpty) {
        throw Exception(
          'لم يعثر محرك الخرائط على أي مسار.',
        );
      }

      final List<RouteOption> calculated = [];

      for (int i = 0; i < rawRoutes.length; i++) {
        final route = rawRoutes[i];

        final coordinates =
            route['geometry']['coordinates'] as List;

        final points = <LatLng>[];

        for (final coordinate in coordinates) {
          if (coordinate is List &&
              coordinate.length >= 2) {
            final lng =
                (coordinate[0] as num).toDouble();

            final lat =
                (coordinate[1] as num).toDouble();

            points.add(
              LatLng(lat, lng),
            );
          }
        }

        final distanceKm =
            (route['distance'] as num).toDouble() /
                1000.0;

        final durationMin =
            (route['duration'] as num).toDouble() /
                60.0;

        calculated.add(
          RouteOption(
            distanceKm: distanceKm,
            durationMin: durationMin,
            points: points,
            name: 'المسار ${i + 1}',
            isMain: false,
            source: 'online',
          ),
        );
      }

      /// ترتيب المسارات حسب المسافة.
      calculated.sort(
        (a, b) =>
            a.distanceKm.compareTo(b.distanceKm),
      );

      final finalRoutes = <RouteOption>[];

      for (int i = 0; i < calculated.length; i++) {
        final r = calculated[i];

        finalRoutes.add(
          RouteOption(
            distanceKm: r.distanceKm,
            durationMin: r.durationMin,
            points: r.points,
            name: i == 0
                ? 'المسار الرئيسي'
                : 'مسار بديل ${i}',
            isMain: i == 0,
            source: 'online',
          ),
        );
      }

      /// حفظ المسارات للأوفلاين.
      await OfflineMapService.saveRoutes(
        latitude: fromLat,
        longitude: fromLng,
        destinationLatitude: widget.place.lat,
        destinationLongitude: widget.place.lng,
        destinationName: widget.place.name,
        routes: finalRoutes,
      );

      if (!mounted) return;

      setState(() {
        _routes = finalRoutes;
        _selectedRoute = 0;
        _loadingRoutes = false;
      });

      _fitMapToRoute();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingRoutes = false;
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  /// ===============================================================
  /// محرك أوفلاين
  ///
  /// يستخدم المسارات التي تم تنزيلها وحفظها سابقًا.
  /// ===============================================================

  Future<void> _calculateOfflineRoutes() async {
    setState(() {
      _loadingRoutes = true;
      _routes = [];
      _error = null;
    });

    try {
      final routes =
          await OfflineMapService.getSavedRoutes(
        destinationLatitude: widget.place.lat,
        destinationLongitude: widget.place.lng,
        destinationName: widget.place.name,
      );

      if (routes.isEmpty) {
        throw Exception(
          'لا توجد مسارات أوفلاين محفوظة لهذه الوجهة.\n'
          'اتصل بالإنترنت أولًا واختر الخريطة الأونلاين '
          'لحساب المسارات وحفظها للاستخدام بدون إنترنت.',
        );
      }

      /// إعادة ترتيب حسب المسافة.
      routes.sort(
        (a, b) =>
            a.distanceKm.compareTo(b.distanceKm),
      );

      final fixed = <RouteOption>[];

      for (int i = 0; i < routes.length; i++) {
        final route = routes[i];

        fixed.add(
          RouteOption(
            distanceKm: route.distanceKm,
            durationMin: route.durationMin,
            points: route.points,
            name: i == 0
                ? 'المسار الرئيسي'
                : 'مسار بديل $i',
            isMain: i == 0,
            source: 'offline',
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _routes = fixed;
        _selectedRoute = 0;
        _loadingRoutes = false;
      });

      _fitMapToRoute();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingRoutes = false;
        _error = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  /// ===============================================================
  /// تغيير المحرك
  /// ===============================================================

  void _setMapMode(bool online) {
    if (_onlineMode == online) return;

    setState(() {
      _onlineMode = online;
      _routes = [];
      _error = null;
    });
  }

  /// ===============================================================
  /// اختيار المسار
  /// ===============================================================

  void _selectRoute(int index) {
    if (index < 0 || index >= _routes.length) {
      return;
    }

    setState(() {
      _selectedRoute = index;
    });

    _fitMapToRoute();
  }

  /// ===============================================================
  /// ضبط الخريطة
  /// ===============================================================

  void _fitMapToRoute() {
    if (_routes.isEmpty) return;

    final points = _routes[_selectedRoute].points;

    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;

    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);

      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;

    final maxDiff = max(
      latDiff,
      lngDiff,
    );

    double zoom = 10;

    if (maxDiff < 0.02) {
      zoom = 14;
    } else if (maxDiff < 0.05) {
      zoom = 12;
    } else if (maxDiff < 0.15) {
      zoom = 10;
    } else if (maxDiff < 0.5) {
      zoom = 8;
    } else if (maxDiff < 1.5) {
      zoom = 7;
    } else {
      zoom = 6;
    }

    try {
      _mapController.move(
        center,
        zoom,
      );
    } catch (_) {}
  }

  /// ===============================================================
  /// فتح Google Maps للملاحة الخارجية
  /// ===============================================================

  Future<void> _openExternalNavigation() async {
    if (_position == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_position!.latitude},${_position!.longitude}'
      '&destination=${widget.place.lat},${widget.place.lng}'
      '&travelmode=driving',
    );

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  /// ===============================================================
  /// بناء
  /// ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'الخرائط',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: _loadingLocation
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildDestinationHeader(),
                const SizedBox(height: 12),
                _buildMapModeSelector(),
                const SizedBox(height: 12),
                _buildRouteEngineButton(),
                const SizedBox(height: 12),
                if (_error != null) _buildError(),
                if (_routes.isNotEmpty) ...[
                  _buildRouteSummary(),
                  const SizedBox(height: 12),
                  _buildMap(),
                  const SizedBox(height: 12),
                  _buildRouteCards(),
                ],
                const SizedBox(height: 12),
                _buildExternalNavigationButton(),
                const SizedBox(height: 20),
                _buildIraqiProvinces(),
              ],
            ),
    );
  }

  /// ===============================================================
  /// الوجهة
  /// ===============================================================

  Widget _buildDestinationHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            widget.place.icon,
            color: Colors.white,
            size: 42,
          ),
          const SizedBox(height: 8),
          Text(
            widget.place.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            widget.place.subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          if (_straightDistance != null) ...[
            const SizedBox(height: 10),
            Text(
              'المسافة المباشرة: '
              '${_straightDistance!.toStringAsFixed(1)} كم',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ===============================================================
  /// اختيار أونلاين / أوفلاين
  /// ===============================================================

  Widget _buildMapModeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'اختر نوع الخريطة',
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    title: 'الخريطة أونلاين',
                    subtitle: 'حساب المسارات مباشرة',
                    icon: Icons.public,
                    selected: _onlineMode,
                    color: AppColors.primaryGreen,
                    onTap: () => _setMapMode(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ModeButton(
                    title: 'الخريطة أوفلاين',
                    subtitle: 'المسارات المحفوظة',
                    icon: Icons.download,
                    selected: !_onlineMode,
                    color: Colors.brown,
                    onTap: () => _setMapMode(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ===============================================================
  /// زر تشغيل المحرك
  /// ===============================================================

  Widget _buildRouteEngineButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _loadingRoutes ? null : _calculateRoutes,
        icon: _loadingRoutes
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.alt_route,
                color: Colors.white,
              ),
        label: Text(
          _loadingRoutes
              ? 'جاري حساب المسارات...'
              : _onlineMode
                  ? 'حساب جميع المسارات'
                  : 'عرض المسارات الأوفلاين',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _onlineMode
              ? AppColors.primaryGreen
              : Colors.brown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 15,
          ),
        ),
      ),
    );
  }

  /// ===============================================================
  /// خطأ
  /// ===============================================================

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(
          color: Colors.red.shade300,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _calculateRoutes,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ===============================================================
  /// ملخص المسار
  /// ===============================================================

  Widget _buildRouteSummary() {
    if (_routes.isEmpty) {
      return const SizedBox.shrink();
    }

    final route = _routes[_selectedRoute];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              route.isMain
                  ? '⭐ المسار الرئيسي'
                  : route.name,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                    icon: Icons.route,
                    title: 'المسافة',
                    value:
                        '${route.distanceKm.toStringAsFixed(1)} كم',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _InfoBox(
                    icon: Icons.access_time,
                    title: 'الوقت',
                    value:
                        _formatDuration(route.durationMin),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _onlineMode
                  ? 'المعلومات محسوبة من محرك التوجيه الأونلاين.'
                  : 'المعلومات من المسارات المحفوظة على الجهاز.',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(double minutes) {
    final totalMinutes = minutes.round();

    if (totalMinutes < 60) {
      return '$totalMinutes دقيقة';
    }

    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;

    if (mins == 0) {
      return '$hours ساعة';
    }

    return '$hours س و $mins د';
  }

  /// ===============================================================
  /// الخريطة
  /// ===============================================================

  Widget _buildMap() {
    final selected =
        _routes.isNotEmpty
            ? _routes[_selectedRoute]
            : null;

    final center = _position != null
        ? LatLng(
            _position!.latitude,
            _position!.longitude,
          )
        : LatLng(
            widget.place.lat,
            widget.place.lng,
          );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 520,
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 7,
          ),
          children: [
            TileLayer(
              urlTemplate: _tileUrl,
              userAgentPackageName:
                  'com.daleelzuwar.alhussein',
              tileProvider:
                  OfflineFirstTileProvider(),
            ),

            /// جميع المسارات
            if (_routes.isNotEmpty)
              PolylineLayer(
                polylines: [
                  for (int i = 0;
                      i < _routes.length;
                      i++)
                    if (i != _selectedRoute)
                      Polyline(
                        points:
                            _routes[i].points,
                        color:
                            Colors.grey.shade600,
                        strokeWidth: 4,
                      ),

                  /// المسار المحدد
                  if (selected != null)
                    Polyline(
                      points:
                          selected.points,
                      color:
                          selected.isMain
                              ? AppColors
                                  .primaryGreen
                              : Colors.blue,
                      strokeWidth: 7,
                      borderStrokeWidth: 2,
                      borderColor:
                          Colors.white,
                    ),
                ],
              ),

            MarkerLayer(
              markers: [
                /// الموقع
                if (_position != null)
                  Marker(
                    point: LatLng(
                      _position!.latitude,
                      _position!.longitude,
                    ),
                    width: 65,
                    height: 65,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 42,
                        ),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          color: Colors.blue,
                          child: const Text(
                            'أنت هنا',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                /// الوجهة
                Marker(
                  point: LatLng(
                    widget.place.lat,
                    widget.place.lng,
                  ),
                  width: 90,
                  height: 75,
                  child: Column(
                    children: [
                      Icon(
                        widget.place.icon,
                        color:
                            AppColors.primaryGreen,
                        size: 42,
                      ),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.primaryGreen,
                          borderRadius:
                              BorderRadius.circular(
                            4,
                          ),
                        ),
                        child: Text(
                          widget.place.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ===============================================================
  /// بطاقات المسارات
  /// ===============================================================

  Widget _buildRouteCards() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'المسارات المتاحة',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(
          _routes.length,
          (index) {
            final route = _routes[index];
            final selected =
                index == _selectedRoute;

            return Card(
              margin:
                  const EdgeInsets.only(bottom: 8),
              color: selected
                  ? AppColors.primaryGreen
                  : Colors.white,
              child: InkWell(
                onTap: () =>
                    _selectRoute(index),
                child: Padding(
                  padding:
                      const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            selected
                                ? Colors.white
                                : AppColors
                                    .primaryGreen,
                        child: Icon(
                          route.isMain
                              ? Icons.star
                              : Icons.alt_route,
                          color: selected
                              ? AppColors
                                  .primaryGreen
                              : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.isMain
                                  ? '⭐ المسار الرئيسي'
                                  : route.name,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${route.distanceKm.toStringAsFixed(1)} كم • '
                              '${_formatDuration(route.durationMin)}',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.black,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected
                            ? Colors.white
                            : Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// ===============================================================
  /// زر الملاحة الخارجية
  /// ===============================================================

  Widget _buildExternalNavigationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _openExternalNavigation,
        icon: const Icon(
          Icons.navigation,
          color: Colors.white,
        ),
        label: const Text(
          'فتح الملاحة الخارجية',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
        ),
      ),
    );
  }

  /// ===============================================================
  /// المحافظات العراقية
  /// ===============================================================

  Widget _buildIraqiProvinces() {
    final provinces = _getProvinces();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'المحافظات العراقية',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'يمكنك استخدام المحافظات كنقاط انطلاق للبحث عن الطرق.',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provinces
                  .map(
                    (province) => Chip(
                      avatar: const Icon(
                        Icons.location_city,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        province,
                        style:
                            const TextStyle(
                          color: Colors.white,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      backgroundColor:
                          AppColors.primaryGreen,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getProvinces() {
    return [
      'بغداد',
      'الأنبار',
      'بابل',
      'كربلاء',
      'النجف',
      'الديوانية',
      'المثنى',
      'ذي قار',
      'ميسان',
      'البصرة',
      'واسط',
      'ديالى',
      'صلاح الدين',
      'كركوك',
      'نينوى',
      'أربيل',
      'السليمانية',
      'دهوك',
    ];
  }
}

/// ===============================================================
/// Mode Button
/// ===============================================================

class _ModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? color
          : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? Colors.white
                    : Colors.black,
                size: 32,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.black,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// Info Box
/// ===============================================================

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoBox({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.black,
            size: 24,
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
