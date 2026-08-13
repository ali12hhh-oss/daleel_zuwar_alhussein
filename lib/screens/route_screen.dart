import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/cities_data.dart';
import '../models/models.dart';
import '../services/offline_map_service.dart';
import '../theme.dart';

enum MapChoice { google, online, offline }

/// مسار أعاده محرك التوجيه.
class RouteOption {
  final double distanceKm;
  final double durationMin;
  final List<LatLng> points;
  final String name;
  final bool isMain;
  final String source;
  final List<String> instructions;

  const RouteOption({
    required this.distanceKm,
    required this.durationMin,
    required this.points,
    required this.name,
    required this.isMain,
    required this.source,
    this.instructions = const <String>[],
  });

  SavedRoute toSavedRoute() => SavedRoute(
        distanceKm: distanceKm,
        durationMin: durationMin,
        points: points,
      );
}

/// وجهة مقدسة يمكن للمستخدم اختيارها.
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

/// قائمة الوجهات. المدن العراقية لا تزال محفوظة بالكامل في cities_data.dart.
const List<SacredPlace> sacredPlaces = <SacredPlace>[
  SacredPlace(
    name: 'ضريح الإمام الحسين (ع)',
    subtitle: 'كربلاء المقدسة - العراق',
    lat: 32.61639,
    lng: 44.03250,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'ضريح أبي الفضل العباس (ع)',
    subtitle: 'كربلاء المقدسة - العراق',
    lat: 32.61670,
    lng: 44.03360,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'ضريح الإمام علي (ع)',
    subtitle: 'النجف الأشرف - العراق',
    lat: 32.00060,
    lng: 44.32400,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'مقبرة وادي السلام',
    subtitle: 'النجف الأشرف - العراق',
    lat: 32.00910,
    lng: 44.31880,
    icon: Icons.location_city,
  ),
  SacredPlace(
    name: 'مسجد الكوفة',
    subtitle: 'الكوفة - العراق',
    lat: 32.02800,
    lng: 44.40100,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'مسجد السهلة',
    subtitle: 'الكوفة - العراق',
    lat: 32.01570,
    lng: 44.37580,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'مرقد الإمامين الكاظم والجواد (ع)',
    subtitle: 'الكاظمية - بغداد - العراق',
    lat: 33.37500,
    lng: 44.34480,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'مرقد الإمامين العسكريين (ع)',
    subtitle: 'سامراء - العراق',
    lat: 34.19950,
    lng: 43.87500,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'مرقد الإمام علي بن موسى الرضا (ع)',
    subtitle: 'مشهد - إيران',
    lat: 36.28750,
    lng: 59.61680,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'مرقد السيدة فاطمة المعصومة (ع)',
    subtitle: 'قم - إيران',
    lat: 34.64160,
    lng: 50.87570,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'مرقد السيدة زينب (ع)',
    subtitle: 'ريف دمشق - سوريا',
    lat: 33.45040,
    lng: 36.34980,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'المسجد النبوي الشريف',
    subtitle: 'المدينة المنورة - السعودية',
    lat: 24.46720,
    lng: 39.61120,
    icon: Icons.mosque,
  ),
  SacredPlace(
    name: 'أئمة البقيع (ع)',
    subtitle: 'مقبرة البقيع - المدينة المنورة - السعودية',
    lat: 24.46700,
    lng: 39.61360,
    icon: Icons.mosque,
  ),
];

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  SacredPlace? _selectedPlace;
  bool _showMapsPage = false;

  @override
  Widget build(BuildContext context) {
    if (_showMapsPage && _selectedPlace != null) {
      return _MapsPage(
        place: _selectedPlace!,
        onBack: () => setState(() => _showMapsPage = false),
      );
    }

    return _PlacesPage(
      onPlaceSelected: (place) => setState(() {
        _selectedPlace = place;
        _showMapsPage = true;
      }),
    );
  }
}

class _PlacesPage extends StatelessWidget {
  final ValueChanged<SacredPlace> onPlaceSelected;

  const _PlacesPage({required this.onPlaceSelected});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardText = dark ? Colors.white : Colors.black;
    final secondary = dark ? Colors.white70 : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المراقد والأماكن المقدسة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderBox(
            icon: Icons.map,
            title: 'اختر المرقد أو المكان المقدس',
            subtitle: 'بعد الاختيار ستنتقل إلى صفحة الخرائط، ثم تختار أونلاين أو أوفلاين.',
          ),
          const SizedBox(height: 18),
          ...sacredPlaces.map(
            (place) => _SacredPlaceCard(
              place: place,
              titleColor: cardText,
              subtitleColor: secondary,
              onTap: () => onPlaceSelected(place),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HeaderBox({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 42),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SacredPlaceCard extends StatelessWidget {
  final SacredPlace place;
  final Color titleColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _SacredPlaceCard({
    required this.place,
    required this.titleColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(place.icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: titleColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapsPage extends StatefulWidget {
  final SacredPlace place;
  final VoidCallback onBack;

  const _MapsPage({required this.place, required this.onBack});

  @override
  State<_MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<_MapsPage> {
  Position? _position;
  bool _loadingLocation = true;
  bool _loadingRoutes = false;
  bool _downloadingMap = false;
  String? _error;
  String _downloadStatus = '';

  List<RouteOption> _routes = <RouteOption>[];
  int _selectedRoute = 0;
  bool _onlineMode = true;
  MapChoice _mapChoice = MapChoice.online;
  double? _straightDistance;
  IraqiCity? _selectedCity;

  final MapController _mapController = MapController();

  static const String _tileUrl = OfflineMapService.tileUrlTemplate;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await OfflineMapService.init();
    await _getLocation();
  }

  Future<void> _getLocation() async {
    if (mounted) {
      setState(() {
        _loadingLocation = true;
        _error = null;
      });
    }

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('يرجى تفعيل خدمة الموقع GPS من إعدادات الجهاز.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('تم رفض إذن الوصول إلى الموقع.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('إذن الموقع مرفوض بشكل دائم. فعّل الإذن من إعدادات التطبيق.');
      }

      // متوافق مع geolocator 11.x: لا نستخدم locationSettings هنا.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _position = position;
        _straightDistance = _haversineKm(
          position.latitude,
          position.longitude,
          widget.place.lat,
          widget.place.lng,
        );
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const radius = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return radius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double get _originLat => _selectedCity?.lat ?? _position!.latitude;
  double get _originLng => _selectedCity?.lng ?? _position!.longitude;
  bool get _usingCityOrigin => _selectedCity != null;

  String get _originName => _selectedCity?.name ?? 'موقعي الحالي';

  void _selectCity(IraqiCity city) {
    setState(() {
      _selectedCity = city;
      _routes = <RouteOption>[];
      _selectedRoute = 0;
      _error = null;
      _straightDistance = _haversineKm(
        city.lat,
        city.lng,
        widget.place.lat,
        widget.place.lng,
      );
    });

    _mapController.move(LatLng(city.lat, city.lng), 8);
    _calculateRoutes();
  }

  void _selectCurrentLocation() {
    setState(() {
      _selectedCity = null;
      _routes = <RouteOption>[];
      _selectedRoute = 0;
      _error = null;
      if (_position != null) {
        _straightDistance = _haversineKm(
          _position!.latitude,
          _position!.longitude,
          widget.place.lat,
          widget.place.lng,
        );
      }
    });
    if (_position != null) {
      _mapController.move(LatLng(_position!.latitude, _position!.longitude), 8);
    }
  }

  Future<void> _calculateRoutes() async {
    if (_selectedCity == null && _position == null) {
      await _getLocation();
    }
    if (_selectedCity == null && _position == null) return;

    if (_onlineMode) {
      await _calculateOnlineRoutes();
    } else {
      await _calculateOfflineRoutes();
    }
  }

  Future<void> _calculateOnlineRoutes() async {
    setState(() {
      _loadingRoutes = true;
      _routes = <RouteOption>[];
      _error = null;
    });

    try {
      final fromLat = _originLat;
      final fromLng = _originLng;

      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$fromLng,$fromLat;${widget.place.lng},${widget.place.lat}'
        '?overview=full&geometries=geojson&alternatives=true&steps=true',
      );

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
          'User-Agent': 'daleel-zuwar-alhussein/1.0',
        },
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode != 200) {
        throw Exception('تعذر الاتصال بمحرك حساب الطرق. حاول مرة أخرى.');
      }

      final data = jsonDecode(response.body);
      if (data is! Map || data['code'] != 'Ok') {
        throw Exception('لم يتم العثور على طريق مناسب لهذه الوجهة.');
      }

      final rawRoutes = data['routes'];
      if (rawRoutes is! List || rawRoutes.isEmpty) {
        throw Exception('لم يعثر محرك الخرائط على أي مسار.');
      }

      final calculated = <RouteOption>[];
      for (final raw in rawRoutes) {
        if (raw is! Map) continue;
        final geometry = raw['geometry'];
        final coordinates = geometry is Map ? geometry['coordinates'] : null;
        if (coordinates is! List) continue;

        final points = <LatLng>[];
        for (final coordinate in coordinates) {
          if (coordinate is List && coordinate.length >= 2) {
            final lng = (coordinate[0] as num?)?.toDouble();
            final lat = (coordinate[1] as num?)?.toDouble();
            if (lat != null && lng != null) points.add(LatLng(lat, lng));
          }
        }

        final distance = (raw['distance'] as num?)?.toDouble();
        final duration = (raw['duration'] as num?)?.toDouble();
        if (distance == null || duration == null || points.length < 2) continue;

        final instructions = <String>[];
        final legs = raw['legs'];
        if (legs is List) {
          for (final leg in legs) {
            if (leg is! Map) continue;
            final steps = leg['steps'];
            if (steps is! List) continue;
            for (final step in steps) {
              if (step is! Map) continue;
              final maneuver = step['maneuver'];
              final type = maneuver is Map ? maneuver['type']?.toString() : null;
              final modifier = maneuver is Map ? maneuver['modifier']?.toString() : null;
              final name = step['name']?.toString();
              final instruction = _instructionText(type, modifier, name);
              if (instruction.isNotEmpty) instructions.add(instruction);
            }
          }
        }

        calculated.add(RouteOption(
          distanceKm: distance / 1000,
          durationMin: duration / 60,
          points: points,
          name: 'مسار',
          isMain: false,
          source: 'online',
          instructions: instructions.take(12).toList(),
        ));
      }

      if (calculated.isEmpty) {
        throw Exception('المحرك أعاد نتيجة غير صالحة للمسار.');
      }

      calculated.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      final finalRoutes = <RouteOption>[];
      for (var i = 0; i < calculated.length; i++) {
        final r = calculated[i];
        finalRoutes.add(RouteOption(
          distanceKm: r.distanceKm,
          durationMin: r.durationMin,
          points: r.points,
          name: i == 0 ? 'المسار الأقرب' : 'مسار بديل ${i}',
          isMain: i == 0,
          source: 'online',
          instructions: r.instructions,
        ));
      }

      await OfflineMapService.saveRoutes(
        latitude: fromLat,
        longitude: fromLng,
        destinationLatitude: widget.place.lat,
        destinationLongitude: widget.place.lng,
        destinationName: widget.place.name,
        routes: finalRoutes.map((r) => r.toSavedRoute()).toList(),
      );

      if (!mounted) return;
      setState(() {
        _routes = finalRoutes;
        _selectedRoute = 0;
        _loadingRoutes = false;
      });
      _fitMapToPoints(finalRoutes.first.points);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRoutes = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _calculateOfflineRoutes() async {
    setState(() {
      _loadingRoutes = true;
      _routes = <RouteOption>[];
      _error = null;
    });

    try {
      final saved = await OfflineMapService.getSavedRoutes(
        destinationLatitude: widget.place.lat,
        destinationLongitude: widget.place.lng,
        destinationName: widget.place.name,
        fromLatitude: _selectedCity?.lat ?? _position?.latitude,
        fromLongitude: _selectedCity?.lng ?? _position?.longitude,
      );

      if (saved.isEmpty) {
        throw Exception(
          'لا توجد مسارات محفوظة لهذه الوجهة من $_originName.\n'
          'اتصل بالإنترنت، احسب المسارات أولاً، ثم استخدم الأوفلاين لاحقاً.',
        );
      }

      saved.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      final routes = <RouteOption>[];
      for (var i = 0; i < saved.length; i++) {
        final r = saved[i];
        routes.add(RouteOption(
          distanceKm: r.distanceKm,
          durationMin: r.durationMin,
          points: r.points,
          name: i == 0 ? 'المسار الأقرب' : 'مسار بديل $i',
          isMain: i == 0,
          source: 'offline',
        ));
      }

      if (!mounted) return;
      setState(() {
        _routes = routes;
        _selectedRoute = 0;
        _loadingRoutes = false;
      });
      _fitMapToPoints(routes.first.points);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRoutes = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _setMapChoice(MapChoice choice) {
    if (_mapChoice == choice) return;
    setState(() {
      _mapChoice = choice;
      _onlineMode = choice == MapChoice.online;
      _routes = <RouteOption>[];
      _error = null;
      _downloadStatus = '';
    });
  }

  Future<void> _openSelectedMap() async {
    if (_selectedCity == null && _position == null) {
      await _getLocation();
    }
    if (_position == null && _selectedCity == null) return;

    if (_mapChoice == MapChoice.google) {
      await _openExternalNavigation();
      return;
    }

    await _calculateRoutes();
    if (!mounted || _routes.isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullMapPage(
          place: widget.place,
          position: _position,
          selectedCity: _selectedCity,
          routes: _routes,
          selectedRoute: _selectedRoute,
          online: _mapChoice == MapChoice.online,
          onDownload: _mapChoice == MapChoice.online ? _downloadCurrentRouteMap : null,
        ),
      ),
    );
  }

  String _instructionText(String? type, String? modifier, String? name) {
    final road = (name == null || name.isEmpty) ? '' : ' على ${name.trim()}';
    switch (type) {
      case 'depart': return 'انطلق${road}';
      case 'arrive': return 'لقد وصلت إلى الوجهة';
      case 'turn':
        final direction = modifier == 'left' ? 'يسارًا' : modifier == 'right' ? 'يمينًا' : 'مباشرة';
        return 'انعطف $direction$road';
      case 'new name': return 'تابع مباشرة$road';
      case 'merge': return 'اندمج في الطريق$road';
      case 'fork': return 'خذ الفرع المناسب$road';
      case 'roundabout': return 'ادخل الدوار$road';
      case 'continue': return 'تابع مباشرة$road';
      default: return road.isEmpty ? 'تابع على الطريق' : 'تابع$road';
    }
  }

  void _selectRoute(int index) {
    if (index < 0 || index >= _routes.length) return;
    setState(() => _selectedRoute = index);
    _fitMapToPoints(_routes[index].points);
  }

  void _fitMapToPoints(List<LatLng> points) {
    if (points.isEmpty) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    final diff = max(maxLat - minLat, maxLng - minLng);
    final zoom = diff < 0.02
        ? 14.0
        : diff < 0.05
            ? 12.0
            : diff < 0.15
                ? 10.0
                : diff < 0.5
                    ? 8.0
                    : diff < 1.5
                        ? 7.0
                        : 5.5;

    try {
      _mapController.move(center, zoom);
    } catch (_) {}
  }

  Future<void> _downloadCurrentRouteMap() async {
    if (_routes.isEmpty) return;

    final allPoints = <LatLng>[];
    for (final route in _routes) {
      allPoints.addAll(route.points);
    }
    if (allPoints.isEmpty) return;

    setState(() {
      _downloadingMap = true;
      _downloadStatus = 'جاري تجهيز خريطة الرحلة للأوفلاين...';
    });

    try {
      var minLat = allPoints.first.latitude;
      var maxLat = allPoints.first.latitude;
      var minLng = allPoints.first.longitude;
      var maxLng = allPoints.first.longitude;
      for (final p in allPoints) {
        minLat = min(minLat, p.latitude);
        maxLat = max(maxLat, p.latitude);
        minLng = min(minLng, p.longitude);
        maxLng = max(maxLng, p.longitude);
      }

      const margin = 0.08;
      minLat = max(-85.0, minLat - margin);
      maxLat = min(85.0, maxLat + margin);
      minLng = max(-180.0, minLng - margin);
      maxLng = min(180.0, maxLng + margin);

      final diff = max(maxLat - minLat, maxLng - minLng);
      final maxZoom = diff > 10
          ? 7
          : diff > 5
              ? 8
              : diff > 2
                  ? 9
                  : 11;

      await OfflineMapService.downloadRegion(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
        minZoom: 5,
        maxZoom: maxZoom,
        onProgress: (downloaded, total, failed) {
          if (!mounted) return;
          setState(() {
            final percent = total == 0 ? 100 : (downloaded / total * 100).round();
            _downloadStatus = 'تحميل خريطة الرحلة: $percent%  •  فشل: $failed';
          });
        },
      );

      final size = await OfflineMapService.getCacheSizeMb();
      if (!mounted) return;
      setState(() {
        _downloadingMap = false;
        _downloadStatus = 'تم حفظ خريطة الرحلة والمسارات للأوفلاين (${size.toStringAsFixed(1)} م.ب).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _downloadingMap = false;
        _downloadStatus = 'تعذر تحميل خريطة الرحلة. تحقق من الإنترنت وحاول مرة أخرى.';
      });
    }
  }

  Future<void> _openExternalNavigation() async {
    if (_selectedCity == null && _position == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_originLat},${_originLng}'
      '&destination=${widget.place.lat},${widget.place.lng}'
      // وضع المشي هو الأنسب لطبيعة التطبيق (زائر يمشي إلى العتبة)؛
      // خرائط جوجل تدعم وضع المشي مباشرة (بخلاف محرك OSRM المستخدم
      // للمسارات داخل التطبيق، الذي يوفر خادمه العام وضع القيادة فقط).
      '&travelmode=walking',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      _showMessage('تعذر فتح تطبيق الخرائط الخارجي.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDuration(double minutes) {
    final total = max(0, minutes.round());
    if (total < 60) return '$total دقيقة';
    final hours = total ~/ 60;
    final mins = total % 60;
    return mins == 0 ? '$hours ساعة' : '$hours س و $mins د';
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLocation) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
          title: const Text('الوجهة والخرائط'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
        title: const Text('الوجهة والخرائط'),
      ),
      body: RefreshIndicator(
        onRefresh: _getLocation,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _buildDestinationHeader(context),
            const SizedBox(height: 12),
            _buildOriginSelector(context),
            const SizedBox(height: 12),
            _buildMapModeSelector(context),
            const SizedBox(height: 12),
            _buildRouteEngineButton(context),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _buildError(context),
            ],
            const SizedBox(height: 16),
            _buildCities(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationHeader(BuildContext context) {
    return _HeaderBox(
      icon: widget.place.icon,
      title: widget.place.name,
      subtitle: widget.place.subtitle +
          (_straightDistance == null
              ? ''
              : '\nأقرب مسافة: ${_straightDistance!.toStringAsFixed(1)} كم'),
    );
  }

  Widget _buildMapModeSelector(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('اختر الخريطة', style: TextStyle(color: _textColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _MapChoiceButton(
              title: 'خرائط كوكل',
              subtitle: 'فتح الملاحة في تطبيق خرائط كوكل',
              icon: Icons.map,
              selected: _mapChoice == MapChoice.google,
              color: AppColors.gold,
              onTap: () => _setMapChoice(MapChoice.google),
            ),
            const SizedBox(height: 10),
            _MapChoiceButton(
              title: 'خرائط أونلاين',
              subtitle: 'خريطة ومسارات داخل التطبيق عبر الإنترنت',
              icon: Icons.public,
              selected: _mapChoice == MapChoice.online,
              color: AppColors.primaryGreen,
              onTap: () => _setMapChoice(MapChoice.online),
            ),
            const SizedBox(height: 10),
            _MapChoiceButton(
              title: 'الخريطة أوفلاين',
              subtitle: 'المسارات والبلاطات المحفوظة على الجهاز',
              icon: Icons.cloud_off,
              selected: _mapChoice == MapChoice.offline,
              color: Colors.blueGrey.shade800,
              onTap: () => _setMapChoice(MapChoice.offline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOriginSelector(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.trip_origin, color: AppColors.primaryGreen, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نقطة الانطلاق', style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(_originName, style: TextStyle(color: dark ? Colors.white70 : Colors.black87)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _position == null ? null : _selectCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('موقعي الحالي'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteEngineButton(BuildContext context) {
    final buttonColor = _onlineMode ? AppColors.primaryGreen : Colors.blueGrey.shade800;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loadingRoutes ? null : _openSelectedMap,
        icon: _loadingRoutes
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.alt_route),
        label: Text(_loadingRoutes
            ? 'جاري حساب المسارات...'
            : 'عرض المسارات وحساب المسافة'),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF3A1717) : const Color(0xFFFFE7E7),
        border: Border.all(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 30),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: _textColor(context), fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _calculateRoutes,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSummary(BuildContext context) {
    final route = _routes[_selectedRoute];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(
              route.isMain ? '⭐ المسار الأقرب' : route.name,
              style: TextStyle(color: _textColor(context), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _InfoBox(icon: Icons.route, title: 'المسافة', value: '${route.distanceKm.toStringAsFixed(1)} كم')),
                const SizedBox(width: 8),
                Expanded(child: _InfoBox(icon: Icons.access_time, title: 'الوقت', value: _formatDuration(route.durationMin))),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _onlineMode
                  ? 'المسافة والوقت حسب محرك التوجيه. الوقت لا يتضمن حركة المرور اللحظية.'
                  : 'المعلومات مأخوذة من المسارات المحفوظة على الجهاز.',
              style: TextStyle(color: _secondaryTextColor(context), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selected = _routes[_selectedRoute];
    final center = _selectedCity != null
        ? LatLng(_selectedCity!.lat, _selectedCity!.lng)
        : (_position == null
            ? LatLng(widget.place.lat, widget.place.lng)
            : LatLng(_position!.latitude, _position!.longitude));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 520,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 7),
              children: [
                TileLayer(
                  urlTemplate: _tileUrl,
                  subdomains: const <String>[],
                  userAgentPackageName: 'com.daleelzuwar.alhussein',
                  tileProvider: _onlineMode
                      ? NetworkTileProvider()
                      : OfflineOnlyTileProvider(),
                ),
                PolylineLayer(
                  polylines: [
                    for (var i = 0; i < _routes.length; i++)
                      if (i != _selectedRoute)
                        Polyline(
                          points: _routes[i].points,
                          color: dark ? Colors.white54 : Colors.black38,
                          strokeWidth: 4,
                        ),
                    Polyline(
                      points: selected.points,
                      color: AppColors.primaryGreen,
                      strokeWidth: 7,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    if (_selectedCity != null)
                      Marker(
                        point: LatLng(_selectedCity!.lat, _selectedCity!.lng),
                        width: 150,
                        height: 78,
                        child: _CityOriginMarker(city: _selectedCity!),
                      )
                    else if (_position != null)
                      Marker(
                        point: LatLng(_position!.latitude, _position!.longitude),
                        width: 80,
                        height: 70,
                        child: const _LocationMarker(),
                      ),
                    Marker(
                      point: LatLng(widget.place.lat, widget.place.lng),
                      width: 130,
                      height: 78,
                      child: _DestinationMarker(place: widget.place),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 10,
              right: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: dark ? Colors.black87 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Text(
                    _onlineMode ? 'الخريطة الأونلاين' : 'الخريطة الأوفلاين',
                    style: TextStyle(color: dark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المسارات التي أعادها المحرك',
          style: TextStyle(color: _textColor(context), fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(_routes.length, (index) {
          final route = _routes[index];
          final selected = index == _selectedRoute;
          final bg = selected ? AppColors.primaryGreen : Theme.of(context).cardColor;
          final fg = selected ? Colors.white : _textColor(context);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: bg,
            child: InkWell(
              onTap: () => _selectRoute(index),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: selected ? Colors.white : AppColors.primaryGreen,
                      child: Icon(route.isMain ? Icons.star : Icons.alt_route, color: selected ? AppColors.primaryGreen : Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.isMain ? '⭐ المسار الأقرب' : route.name,
                            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${route.distanceKm.toStringAsFixed(1)} كم  •  ${_formatDuration(route.durationMin)}',
                            style: TextStyle(color: fg, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: fg),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOfflineSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _downloadingMap ? null : _downloadCurrentRouteMap,
        icon: _downloadingMap
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.download),
        label: Text(_downloadingMap ? 'جاري تحميل الخريطة...' : 'تحميل خريطة الرحلة للأوفلاين'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildExternalNavigationButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openExternalNavigation,
        icon: const Icon(Icons.navigation),
        label: const Text('عرض الملاحة الخارجية'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCities(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('المدن العراقية', style: TextStyle(color: _textColor(context), fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('اختر مركز مدينة ليصبح نقطة الانطلاق إلى ${widget.place.name}.', style: TextStyle(color: _secondaryTextColor(context), fontSize: 13)),
            const SizedBox(height: 12),
            ...iraqiCities.map((city) {
              final selected = _selectedCity?.name == city.name;
              final distance = _haversineKm(city.lat, city.lng, widget.place.lat, widget.place.lng);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: selected ? AppColors.primaryGreen : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => _selectCity(city),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: selected ? Colors.white : AppColors.primaryGreen,
                            child: Icon(Icons.location_city, color: selected ? AppColors.primaryGreen : Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(city.name, style: TextStyle(color: selected ? Colors.white : _textColor(context), fontWeight: FontWeight.bold, fontSize: 15))),
                          Text('${distance.toStringAsFixed(1)} كم', style: TextStyle(color: selected ? Colors.white : _secondaryTextColor(context), fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Icon(selected ? Icons.check_circle : Icons.chevron_left, color: selected ? Colors.white : _textColor(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

  Color _secondaryTextColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87;
}

class _FullMapPage extends StatefulWidget {
  final SacredPlace place;
  final Position? position;
  final IraqiCity? selectedCity;
  final List<RouteOption> routes;
  final int selectedRoute;
  final bool online;
  final Future<void> Function()? onDownload;

  const _FullMapPage({
    required this.place,
    required this.position,
    required this.selectedCity,
    required this.routes,
    required this.selectedRoute,
    required this.online,
    required this.onDownload,
  });

  @override
  State<_FullMapPage> createState() => _FullMapPageState();
}

class _FullMapPageState extends State<_FullMapPage> {
  late int _selectedRoute;
  final MapController _controller = MapController();
  bool _showDetails = true;

  @override
  void initState() {
    super.initState();
    _selectedRoute = min(max(widget.selectedRoute, 0), max(0, widget.routes.length - 1));
  }

  RouteOption get _route => widget.routes[_selectedRoute];

  void _fit(List<LatLng> points) {
    if (points.isEmpty) return;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.fromLTRB(45, 130, 45, 190),
      ),
    );
  }

  String _duration(double minutes) {
    final total = max(0, minutes.round());
    if (total < 60) return '$total دقيقة';
    final h = total ~/ 60;
    final m = total % 60;
    return m == 0 ? '$h ساعة' : '$h س و $m د';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final center = widget.selectedCity != null
        ? LatLng(widget.selectedCity!.lat, widget.selectedCity!.lng)
        : widget.position != null
            ? LatLng(widget.position!.latitude, widget.position!.longitude)
            : LatLng(widget.place.lat, widget.place.lng);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(initialCenter: center, initialZoom: 7),
            children: [
              TileLayer(
                urlTemplate: OfflineMapService.tileUrlTemplate,
                subdomains: const <String>[],
                userAgentPackageName: 'com.daleelzuwar.alhussein',
                tileProvider: widget.online ? NetworkTileProvider() : OfflineOnlyTileProvider(),
              ),
              PolylineLayer(
                polylines: [
                  for (var i = 0; i < widget.routes.length; i++)
                    if (i != _selectedRoute)
                      Polyline(points: widget.routes[i].points, color: dark ? Colors.white54 : Colors.black38, strokeWidth: 4),
                  Polyline(points: _route.points, color: AppColors.primaryGreen, strokeWidth: 7, borderStrokeWidth: 2, borderColor: Colors.white),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (widget.selectedCity != null)
                    Marker(
                      point: LatLng(widget.selectedCity!.lat, widget.selectedCity!.lng),
                      width: 150,
                      height: 78,
                      child: _CityOriginMarker(city: widget.selectedCity!),
                    )
                  else if (widget.position != null)
                    Marker(
                      point: LatLng(widget.position!.latitude, widget.position!.longitude),
                      width: 80,
                      height: 70,
                      child: const _LocationMarker(),
                    ),
                  Marker(
                    point: LatLng(widget.place.lat, widget.place.lng),
                    width: 140,
                    height: 80,
                    child: _DestinationMarker(place: widget.place),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _MapCircleButton(icon: Icons.arrow_back, onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  _MapCircleButton(icon: Icons.place, onTap: () => setState(() => _showDetails = !_showDetails)),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 12,
            right: 12,
            child: _RouteTopInfo(place: widget.place, route: _route, online: widget.online, duration: _duration),
          ),
          if (_showDetails)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: _MapBottomPanel(
                  route: _route,
                  routes: widget.routes,
                  selectedRoute: _selectedRoute,
                  duration: _duration,
                  onRouteSelected: (index) {
                    setState(() => _selectedRoute = index);
                    _fit(widget.routes[index].points);
                  },
                  onFit: () => _fit(_route.points),
                  onDownload: widget.onDownload,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(12), child: Icon(icon, color: Colors.black87)),
      ),
    );
  }
}

class _RouteTopInfo extends StatelessWidget {
  final SacredPlace place;
  final RouteOption route;
  final bool online;
  final String Function(double) duration;

  const _RouteTopInfo({required this.place, required this.route, required this.online, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(place.icon, color: AppColors.primaryGreen, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${route.distanceKm.toStringAsFixed(1)} كم  •  ${duration(route.durationMin)}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: online ? AppColors.primaryGreen : Colors.blueGrey.shade800, borderRadius: BorderRadius.circular(8)),
              child: Text(online ? 'أونلاين' : 'أوفلاين', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapBottomPanel extends StatelessWidget {
  final RouteOption route;
  final List<RouteOption> routes;
  final int selectedRoute;
  final String Function(double) duration;
  final ValueChanged<int> onRouteSelected;
  final VoidCallback onFit;
  final Future<void> Function()? onDownload;

  const _MapBottomPanel({
    required this.route,
    required this.routes,
    required this.selectedRoute,
    required this.duration,
    required this.onRouteSelected,
    required this.onFit,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(route.isMain ? 'المسار الأقرب' : route.name, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17))),
                  IconButton(onPressed: onFit, icon: const Icon(Icons.center_focus_strong, color: Colors.black87)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _InfoBox(icon: Icons.route, title: 'المسافة', value: '${route.distanceKm.toStringAsFixed(1)} كم')),
                  const SizedBox(width: 8),
                  Expanded(child: _InfoBox(icon: Icons.access_time, title: 'الوقت', value: duration(route.durationMin))),
                ],
              ),
              if (routes.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: routes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, index) => ChoiceChip(
                      label: Text(index == 0 ? 'الأقرب' : 'بديل $index'),
                      selected: selectedRoute == index,
                      onSelected: (_) => onRouteSelected(index),
                      selectedColor: AppColors.primaryGreen,
                      labelStyle: TextStyle(color: selectedRoute == index ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              if (route.instructions.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('التعليمات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                ...route.instructions.take(6).toList().asMap().entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key + 1}. ', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      Expanded(child: Text(entry.value, style: const TextStyle(color: Colors.black87, fontSize: 12))),
                    ],
                  ),
                )),
              ],
              if (onDownload != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: () { onDownload!(); }, icon: const Icon(Icons.download), label: const Text('حفظ خريطة الرحلة للأوفلاين')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MapChoiceButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _MapChoiceButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected ? color : (dark ? const Color(0xFF26332F) : const Color(0xFFF3F3F3));
    final fg = selected ? Colors.white : (dark ? Colors.white : Colors.black);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: selected ? Colors.white : color, child: Icon(icon, color: selected ? color : Colors.white)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: fg, fontSize: 12)),
              ])),
              Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBg = dark ? const Color(0xFF26332F) : const Color(0xFFF0F0F0);
    final unselectedFg = dark ? Colors.white : Colors.black;
    return Material(
      color: selected ? color : unselectedBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : unselectedFg, size: 32),
              const SizedBox(height: 6),
              Text(title, style: TextStyle(color: selected ? Colors.white : unselectedFg, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(color: selected ? Colors.white : unselectedFg, fontSize: 10), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoBox({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF24322E) : const Color(0xFFF1F1F1);
    final fg = dark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Icon(icon, color: fg, size: 24),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: fg, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class _CityOriginMarker extends StatelessWidget {
  final IraqiCity city;
  const _CityOriginMarker({required this.city});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade900,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Text(city.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
        const Icon(Icons.location_on, color: Colors.blue, size: 32),
      ],
    );
  }
}

class _LocationMarker extends StatelessWidget {
  const _LocationMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.person_pin_circle, color: Colors.blue, size: 44),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4)),
          child: const Text('أنت هنا', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  final SacredPlace place;

  const _DestinationMarker({required this.place});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(place.icon, color: AppColors.primaryGreen, size: 42),
        Container(
          constraints: const BoxConstraints(maxWidth: 125),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(4)),
          child: Text(
            place.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
