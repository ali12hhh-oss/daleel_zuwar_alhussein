import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/cities_data.dart';
import '../models/models.dart';
import '../theme.dart';
import '../services/offline_map_service.dart';

/// ===============================================================
/// خيار مسار واحد
/// ===============================================================
class RouteOption {
  final double distanceKm;
  final double durationMin;
  final List<LatLng> points;
  final String profile;

  RouteOption({
    required this.distanceKm,
    required this.durationMin,
    required this.points,
    required this.profile,
  });
}

/// ===============================================================
/// نقطة دينية / مزار / مقبرة
/// ===============================================================
class ReligiousPlace {
  final String name;
  final String country;
  final double lat;
  final double lng;
  final IconData icon;
  final Color color;

  const ReligiousPlace({
    required this.name,
    required this.country,
    required this.lat,
    required this.lng,
    required this.icon,
    required this.color,
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

  List<RouteOption> _routeOptions = [];
  int _selectedRouteIndex = 0;

  int _downloadedTiles = 0;
  int _totalTiles = 0;
  double? _cachedSizeMb;

  /// =============================================================
  /// الإحداثيات الافتراضية
  /// =============================================================

  /// مرقد الإمام الحسين عليه السلام - كربلاء
  static const double hussainShrineLat = 32.6163;
  static const double hussainShrineLng = 44.0326;

  /// مركز العالم تقريباً حتى لا تبدأ الخريطة دائماً من العراق.
  static const double worldCenterLat = 20.0;
  static const double worldCenterLng = 35.0;

  static const double worldZoom = 2.5;

  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// =============================================================
  /// المراقد والأماكن المهمة خارج العراق + داخل العراق
  /// =============================================================
  ///
  /// يمكنك إضافة أي مكان مستقبلاً بنفس الطريقة.
  ///
  static const List<ReligiousPlace> _religiousPlaces = [
    // -------------------------------------------------------------
    // العراق
    // -------------------------------------------------------------

    ReligiousPlace(
      name: 'مرقد الإمام الحسين عليه السلام',
      country: 'العراق - كربلاء',
      lat: 32.6163,
      lng: 44.0326,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    ReligiousPlace(
      name: 'مرقد أبي الفضل العباس عليه السلام',
      country: 'العراق - كربلاء',
      lat: 32.6161,
      lng: 44.0359,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    ReligiousPlace(
      name: 'مرقد الإمام علي عليه السلام',
      country: 'العراق - النجف',
      lat: 32.0007,
      lng: 44.3267,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    ReligiousPlace(
      name: 'مقبرة وادي السلام',
      country: 'العراق - النجف',
      lat: 32.0066,
      lng: 44.3138,
      icon: Icons.location_city,
      color: Colors.brown,
    ),

    ReligiousPlace(
      name: 'مرقد الإمامين الكاظمين عليهما السلام',
      country: 'العراق - بغداد',
      lat: 33.3794,
      lng: 44.3398,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    ReligiousPlace(
      name: 'مرقد الإمامين العسكريين عليهما السلام',
      country: 'العراق - سامراء',
      lat: 34.1992,
      lng: 43.8742,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    // -------------------------------------------------------------
    // السعودية
    // -------------------------------------------------------------

    ReligiousPlace(
      name: 'مقبرة البقيع',
      country: 'السعودية - المدينة المنورة',
      lat: 24.4672,
      lng: 39.6106,
      icon: Icons.location_city,
      color: Colors.brown,
    ),

    // -------------------------------------------------------------
    // إيران
    // -------------------------------------------------------------

    ReligiousPlace(
      name: 'مرقد الإمام الرضا عليه السلام',
      country: 'إيران - مشهد',
      lat: 36.2875,
      lng: 59.6168,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    ReligiousPlace(
      name: 'مرقد السيدة فاطمة المعصومة عليها السلام',
      country: 'إيران - قم',
      lat: 34.6416,
      lng: 50.8758,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    // -------------------------------------------------------------
    // سوريا
    // -------------------------------------------------------------

    ReligiousPlace(
      name: 'مرقد السيدة زينب عليها السلام',
      country: 'سوريا - دمشق',
      lat: 33.4510,
      lng: 36.3400,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    ReligiousPlace(
      name: 'مرقد السيدة رقية عليها السلام',
      country: 'سوريا - دمشق',
      lat: 33.5115,
      lng: 36.3022,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    // -------------------------------------------------------------
    // مصر
    // -------------------------------------------------------------

    ReligiousPlace(
      name: 'مسجد الإمام الحسين',
      country: 'مصر - القاهرة',
      lat: 30.0476,
      lng: 31.2625,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    ReligiousPlace(
      name: 'مسجد السيدة زينب',
      country: 'مصر - القاهرة',
      lat: 30.0306,
      lng: 31.2387,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    // -------------------------------------------------------------
    // فلسطين
    // -------------------------------------------------------------

    ReligiousPlace(
      name: 'المسجد الأقصى',
      country: 'فلسطين - القدس',
      lat: 31.7767,
      lng: 35.2358,
      icon: Icons.mosque,
      color: Colors.green,
    ),

    // -------------------------------------------------------------
    // تركيا
    // -------------------------------------------------------------

    ReligiousPlace(
      name: 'مقام أبو أيوب الأنصاري',
      country: 'تركيا - إسطنبول',
      lat: 41.0470,
      lng: 28.9338,
      icon: Icons.mosque,
      color: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _initMapAndCache();
    _detectLocation();
  }

  /// =============================================================
  /// الخريطة والكاش
  /// =============================================================

  Future<void> _initMapAndCache() async {
    try {
      await OfflineMapService.init();
      await _loadCachedSize();
    } catch (_) {}
  }

  Future<void> _loadCachedSize() async {
    try {
      final size = await OfflineMapService.getCacheSizeMb();

      if (mounted && size > 0) {
        setState(() {
          _cachedSizeMb = size;
        });
      }
    } catch (_) {}
  }

  /// =============================================================
  /// حساب المسافة الجوية
  /// =============================================================

  double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const radius = 6371.0;

    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radius * c;
  }

  double _deg2rad(double deg) {
    return deg * (pi / 180);
  }

  /// =============================================================
  /// جلب مسارات OSRM
  /// =============================================================

  Future<List<RouteOption>> _fetchRoutes({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required String profile,
  }) async {
    try {
      final url =
          'https://router.project-osrm.org/route/v1/$profile/'
          '$fromLng,$fromLat;$toLng,$toLat'
          '?overview=full'
          '&geometries=geojson'
          '&alternatives=true'
          '&steps=false';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);

      if (data['routes'] == null) {
        return [];
      }

      final routes = data['routes'] as List;

      return routes.map<RouteOption>((route) {
        final distanceKm =
            (route['distance'] as num).toDouble() / 1000.0;

        final durationMin =
            (route['duration'] as num).toDouble() / 60.0;

        final coordinates =
            route['geometry']['coordinates'] as List;

        final points = coordinates.map<LatLng>((coord) {
          return LatLng(
            (coord[1] as num).toDouble(),
            (coord[0] as num).toDouble(),
          );
        }).toList();

        return RouteOption(
          distanceKm: distanceKm,
          durationMin: durationMin,
          points: points,
          profile: profile,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// =============================================================
  /// حساب الطريق إلى مرقد الحسين
  /// =============================================================

  Future<void> _calculateRoadDistance() async {
    if (_position == null) return;

    setState(() {
      _calculatingRoute = true;
      _routeOptions = [];
      _routePoints = [];
    });

    final options = <RouteOption>[];

    final footOptions = await _fetchRoutes(
      fromLat: _position!.latitude,
      fromLng: _position!.longitude,
      toLat: hussainShrineLat,
      toLng: hussainShrineLng,
      profile: 'foot',
    );

    options.addAll(footOptions);

    final drivingOptions = await _fetchRoutes(
      fromLat: _position!.latitude,
      fromLng: _position!.longitude,
      toLat: hussainShrineLat,
      toLng: hussainShrineLng,
      profile: 'driving',
    );

    options.addAll(drivingOptions);

    if (!mounted) return;

    if (options.isEmpty) {
      setState(() {
        _roadDistanceKm = _straightDistanceKm;
        _calculatingRoute = false;
      });

      return;
    }

    options.sort(
      (a, b) => a.distanceKm.compareTo(b.distanceKm),
    );

    setState(() {
      _routeOptions = options;
      _selectedRouteIndex = 0;
      _roadDistanceKm = options.first.distanceKm;
      _routePoints = options.first.points;
      _calculatingRoute = false;
    });
  }

  void _selectRoute(int index) {
    if (index < 0 || index >= _routeOptions.length) {
      return;
    }

    setState(() {
      _selectedRouteIndex = index;
      _roadDistanceKm = _routeOptions[index].distanceKm;
      _routePoints = _routeOptions[index].points;
    });
  }

  /// =============================================================
  /// حساب المسافة من مدينة
  /// =============================================================

  Future<double> _getRoadDistanceToShrine(
    double lat,
    double lng,
  ) async {
    final options = <RouteOption>[];

    options.addAll(
      await _fetchRoutes(
        fromLat: lat,
        fromLng: lng,
        toLat: hussainShrineLat,
        toLng: hussainShrineLng,
        profile: 'foot',
      ),
    );

    options.addAll(
      await _fetchRoutes(
        fromLat: lat,
        fromLng: lng,
        toLat: hussainShrineLat,
        toLng: hussainShrineLng,
        profile: 'driving',
      ),
    );

    if (options.isNotEmpty) {
      options.sort(
        (a, b) => a.distanceKm.compareTo(b.distanceKm),
      );

      return options.first.distanceKm;
    }

    return _haversineKm(
          lat,
          lng,
          hussainShrineLat,
          hussainShrineLng,
        ) *
        1.3;
  }

  /// =============================================================
  /// تحديد الموقع
  ///
  /// مهم:
  /// تم حذف locationSettings حتى يعمل مع geolocator 11.1.0
  /// =============================================================

  Future<void> _detectLocation() async {
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
          'يرجى تفعيل خدمة الموقع (GPS) في جهازك.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          throw Exception(
            'تم رفض إذن الوصول إلى الموقع.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'إذن الموقع مرفوض بشكل دائم. افتح إعدادات التطبيق وفعّل الموقع.',
        );
      }

      /// متوافق مع geolocator 11.1.0
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      IraqiCity nearest = iraqiCities.first;
      double minDist = double.infinity;

      for (final city in iraqiCities) {
        final distance = _haversineKm(
          pos.latitude,
          pos.longitude,
          city.lat,
          city.lng,
        );

        if (distance < minDist) {
          minDist = distance;
          nearest = city;
        }
      }

      final distToShrine = _haversineKm(
        pos.latitude,
        pos.longitude,
        hussainShrineLat,
        hussainShrineLng,
      );

      if (!mounted) return;

      setState(() {
        _position = pos;
        _nearestCity = nearest;
        _straightDistanceKm = distToShrine;
        _loading = false;
      });

      await _calculateRoadDistance();
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

  /// =============================================================
  /// فتح Google Maps للمشي
  /// =============================================================

  Future<void> _openWalkingDirections() async {
    if (_position == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_position!.latitude},${_position!.longitude}'
      '&destination=$hussainShrineLat,$hussainShrineLng'
      '&travelmode=walking',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذّر فتح تطبيق الخرائط.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _openDirectionsFromCity(
    IraqiCity city,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${city.lat},${city.lng}'
      '&destination=$hussainShrineLat,$hussainShrineLng'
      '&travelmode=walking',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذّر فتح تطبيق الخرائط.',
            ),
          ),
        );
      }
    }
  }

  /// =============================================================
  /// فتح الاتجاهات إلى أي مكان ديني
  /// =============================================================

  Future<void> _openDirectionsToPlace(
    ReligiousPlace place,
  ) async {
    if (_position == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_position!.latitude},${_position!.longitude}'
      '&destination=${place.lat},${place.lng}'
      '&travelmode=walking',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تعذّر فتح تطبيق الخرائط.',
            ),
          ),
        );
      }
    }
  }

  /// =============================================================
  /// تحميل خريطة العراق Offline
  /// =============================================================
  ///
  /// هذه الخريطة تبقى للعراق فقط لأنها مخصصة للعمل بدون إنترنت.
  /// أما الخريطة الرئيسية الآن فهي عالمية.
  /// =============================================================

  Future<void> _cacheIraqMap() async {
    setState(() {
      _isCaching = true;
      _downloadedTiles = 0;
      _totalTiles = 0;
      _cacheStatus =
          'جاري تحضير قائمة التحميل...';
    });

    try {
      await OfflineMapService.downloadRegion(
        minLat: 29.0,
        maxLat: 37.4,
        minLng: 38.7,
        maxLng: 48.8,
        minZoom: 5,
        maxZoom: 10,
        onProgress: (
          downloaded,
          total,
          failed,
        ) {
          if (!mounted) return;

          setState(() {
            _downloadedTiles = downloaded;
            _totalTiles = total;
            _cacheStatus =
                'خريطة العراق: $downloaded من $total';
          });
        },
      );

      /// تفاصيل النجف وكربلاء
      await OfflineMapService.downloadRegion(
        minLat: 31.60,
        maxLat: 32.10,
        minLng: 43.95,
        maxLng: 44.45,
        minZoom: 11,
        maxZoom: 15,
        onProgress: (
          downloaded,
          total,
          failed,
        ) {
          if (!mounted) return;

          setState(() {
            _downloadedTiles = downloaded;
            _totalTiles = total;
            _cacheStatus =
                'تفاصيل النجف وكربلاء: $downloaded من $total';
          });
        },
      );

      final sizeMb =
          await OfflineMapService.getCacheSizeMb();

      if (!mounted) return;

      setState(() {
        _isCaching = false;
        _cachedSizeMb = sizeMb;
        _cacheStatus =
            'تم تحميل خريطة العراق بنجاح '
            '(${sizeMb.toStringAsFixed(1)} م.ب)';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isCaching = false;
        _cacheStatus =
            'فشل التحميل، تأكد من الاتصال بالإنترنت وحاول مجدداً.';
      });
    }
  }

  /// =============================================================
  /// تسمية المسار
  /// =============================================================

  String _routeLabel(
    RouteOption option,
    int index,
  ) {
    final icon =
        option.profile == 'foot' ? '🚶' : '🚗';

    final label =
        option.profile == 'foot'
            ? 'مشي'
            : 'سيارة';

    final sameType = _routeOptions
        .where(
          (o) => o.profile == option.profile,
        )
        .toList();

    if (sameType.length > 1) {
      final typeIndex =
          sameType.indexOf(option) + 1;

      return '$icon $label $typeIndex';
    }

    return '$icon $label';
  }

  /// =============================================================
  /// بناء واجهة الخريطة
  /// =============================================================

  Widget _buildMap() {
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 550,
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(
                worldCenterLat,
                worldCenterLng,
              ),
              initialZoom: worldZoom,
              minZoom: 2,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                subdomains: const [],
                userAgentPackageName:
                    'com.daleelzuwar.alhussein',
                tileProvider:
                    OfflineFirstTileProvider(),
              ),

              /// المسارات
              if (_routeOptions.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    for (
                      int i = 0;
                      i < _routeOptions.length;
                      i++
                    )
                      if (i != _selectedRouteIndex)
                        Polyline(
                          points:
                              _routeOptions[i].points,
                          color: Colors.grey.withOpacity(
                            0.55,
                          ),
                          strokeWidth: 3,
                        ),

                    Polyline(
                      points:
                          _routeOptions[
                            _selectedRouteIndex
                          ].points,
                      color:
                          _routeOptions[
                                _selectedRouteIndex
                              ].profile ==
                              'foot'
                          ? AppColors.primaryGreen
                          : Colors.blue,
                      strokeWidth: 5,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                )
              else if (_position != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        const LatLng(
                          hussainShrineLat,
                          hussainShrineLng,
                        ),
                      ],
                      color: Colors.grey,
                      strokeWidth: 3,
                      strokeCap:
                          StrokeCap.round,
                    ),
                  ],
                ),

              /// العلامات
              MarkerLayer(
                markers: [
                  /// كل المراقد والأماكن
                  ..._religiousPlaces.map(
                    (place) {
                      return Marker(
                        point: LatLng(
                          place.lat,
                          place.lng,
                        ),
                        width: 130,
                        height: 75,
                        child: GestureDetector(
                          onTap: () {
                            _showPlaceDetails(
                              place,
                            );
                          },
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                place.icon,
                                color: place.color,
                                size: 34,
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                decoration:
                                    BoxDecoration(
                                  color: Colors.black
                                      .withOpacity(
                                    0.75,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    4,
                                  ),
                                ),
                                child: Text(
                                  place.name,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  textAlign:
                                      TextAlign.center,
                                  style:
                                      const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  /// موقع المستخدم
                  if (_position != null)
                    Marker(
                      point: LatLng(
                        _position!.latitude,
                        _position!.longitude,
                      ),
                      width: 70,
                      height: 55,
                      child: Column(
                        children: [
                          const Icon(
                            Icons
                                .person_pin_circle,
                            color: Colors.blue,
                            size: 36,
                          ),
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors.blue,
                              borderRadius:
                                  BorderRadius
                                      .circular(4),
                            ),
                            child:
                                const Text(
                              'أنت هنا',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 10,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  /// المدن العراقية
                  ..._getRouteCities().map(
                    (city) {
                      return Marker(
                        point: LatLng(
                          city.lat,
                          city.lng,
                        ),
                        width: 40,
                        height: 40,
                        child: Tooltip(
                          message: city.name,
                          child: Icon(
                            Icons.location_city,
                            color:
                                Colors.orange.shade700,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// =============================================================
  /// تفاصيل المكان
  /// =============================================================

  void _showPlaceDetails(
    ReligiousPlace place,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  place.icon,
                  color: place.color,
                  size: 48,
                ),
                const SizedBox(height: 10),
                Text(
                  place.name,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  place.country,
                  style:
                      TextStyle(
                    color:
                        Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                      _openDirectionsToPlace(
                        place,
                      );
                    },
                    icon: const Icon(
                      Icons.directions,
                    ),
                    label: const Text(
                      'المسار من موقعي',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// =============================================================
  /// الأماكن الموجودة في مسار العراق
  /// =============================================================

  List<IraqiCity> _getRouteCities() {
    const routeCityNames = [
      'بغداد',
      'الحلة',
      'المسيب',
      'الاسكندرية',
      'الهندية',
      'الكفل',
      'عين تمر',
      'الناصرية',
      'العمارة',
      'البصرة',
      'الديوانية',
      'الكوت',
      'الرطبة',
      'الرمادي',
      'الفلوجة',
      'تكريت',
      'الموصل',
      'كركوك',
      'أربيل',
      'السليمانية',
      'دهوك',
      'النجف الأشرف',
      'الكاظمية',
    ];

    return iraqiCities.where(
      (city) =>
          routeCityNames.contains(
            city.name,
          ),
    ).toList();
  }

  /// =============================================================
  /// واجهة التطبيق
  /// =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'طريق زائر الحسين',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _detectLocation,
        child: ListView(
          padding:
              const EdgeInsets.all(16),
          children: [
            /// -----------------------------------------------------
            /// تحميل الموقع
            /// -----------------------------------------------------

            if (_loading)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 40,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ),

            /// -----------------------------------------------------
            /// خطأ
            /// -----------------------------------------------------

            if (_error != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                        onPressed:
                            _detectLocation,
                        child:
                            const Text(
                          'إعادة المحاولة',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            /// -----------------------------------------------------
            /// بطاقة الموقع والمسافة
            /// -----------------------------------------------------

            if (_position != null &&
                _straightDistanceKm != null)
              Card(
                color:
                    AppColors.primaryGreen,
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        'أقرب مدينة معروفة: '
                        '${_nearestCity?.name ?? ''}',
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                        textAlign:
                            TextAlign.center,
                      ),
                      const SizedBox(
                        height: 6,
                      ),
                      Text(
                        'المسافة المستقيمة إلى '
                        'ضريح الإمام الحسين: '
                        '${_straightDistanceKm!.toStringAsFixed(1)} كم',
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 13,
                        ),
                        textAlign:
                            TextAlign.center,
                      ),

                      if (_calculatingRoute) ...[
                        const SizedBox(
                          height: 10,
                        ),
                        const Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Colors.white,
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Text(
                              'جاري حساب الطريق...',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (_roadDistanceKm !=
                          null) ...[
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          'أقصر مسار: '
                          '${_roadDistanceKm!.toStringAsFixed(1)} كم',
                          style:
                              const TextStyle(
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],

                      if (_routeOptions.length >
                          1) ...[
                        const SizedBox(
                          height: 14,
                        ),
                        const Text(
                          'اختر مساراً:',
                          style:
                              TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment:
                              WrapAlignment
                                  .center,
                          children:
                              List.generate(
                            _routeOptions
                                .length,
                            (i) {
                              final opt =
                                  _routeOptions[
                                      i];

                              final selected =
                                  i ==
                                      _selectedRouteIndex;

                              return ChoiceChip(
                                label:
                                    Text(
                                  '${_routeLabel(opt, i)} • '
                                  '${opt.distanceKm.toStringAsFixed(1)} كم',
                                  style:
                                      TextStyle(
                                    fontSize:
                                        12,
                                    color: selected
                                        ? Colors
                                            .white
                                        : Colors
                                            .black87,
                                  ),
                                ),
                                selected:
                                    selected,
                                selectedColor:
                                    AppColors
                                        .gold,
                                backgroundColor:
                                    Colors.white,
                                onSelected:
                                    (_) =>
                                        _selectRoute(
                                  i,
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 14,
                      ),

                      ElevatedButton.icon(
                        onPressed:
                            _openWalkingDirections,
                        icon: const Icon(
                          Icons
                              .directions_walk,
                        ),
                        label: const Text(
                          'عرض مسار المشي إلى الضريح',
                        ),
                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                              AppColors
                                  .gold,
                          foregroundColor:
                              Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(
              height: 16,
            ),

            /// -----------------------------------------------------
            /// بطاقة الخريطة
            /// -----------------------------------------------------

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.public,
                          color:
                              AppColors
                                  .primaryGreen,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'خريطة المراقد والمزارات',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  fontSize:
                                      16,
                                ),
                              ),
                              SizedBox(
                                height: 3,
                              ),
                              Text(
                                'العراق وخارج العراق',
                                style:
                                    TextStyle(
                                  fontSize:
                                      12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton
                              .icon(
                        onPressed: () =>
                            setState(
                          () => _showMap =
                              !_showMap,
                        ),
                        icon: Icon(
                          _showMap
                              ? Icons.map
                              : Icons.map_outlined,
                        ),
                        label: Text(
                          _showMap
                              ? 'إخفاء الخريطة'
                              : 'عرض الخريطة العالمية',
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              AppColors
                                  .primaryGreen,
                          foregroundColor:
                              Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    if (_cachedSizeMb == null)
                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              _isCaching
                                  ? null
                                  : _cacheIraqMap,
                          icon: _isCaching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .download,
                                ),
                          label: Text(
                            _isCaching
                                ? 'جاري التحميل...'
                                : 'تحميل خريطة العراق بدون إنترنت',
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                Colors.blue,
                            foregroundColor:
                                Colors.white,
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          const Icon(
                            Icons
                                .check_circle,
                            color:
                                Colors.green,
                            size: 18,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            'خريطة العراق محمّلة '
                            '(${_cachedSizeMb!.toStringAsFixed(1)} م.ب)',
                            style:
                                const TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.green,
                            ),
                          ),
                        ],
                      ),

                    if (_isCaching &&
                        _totalTiles > 0) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      LinearProgressIndicator(
                        value:
                            _downloadedTiles /
                                _totalTiles,
                        minHeight: 8,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        '${((_downloadedTiles / _totalTiles) * 100).toStringAsFixed(0)}%',
                        style:
                            const TextStyle(
                          fontSize: 11,
                        ),
                      ),
                    ],

                    if (_cacheStatus
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        _cacheStatus,
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize: 12,
                          color: _cacheStatus
                                  .contains(
                                'تم',
                              )
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            /// -----------------------------------------------------
            /// الخريطة
            /// -----------------------------------------------------

            if (_showMap) ...[
              const SizedBox(
                height: 16,
              ),
              _buildMap(),
            ],

            const SizedBox(
              height: 18,
            ),

            /// -----------------------------------------------------
            /// قائمة المراقد خارج العراق
            /// -----------------------------------------------------

            const Text(
              'المراقد والمزارات حول العالم',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            ..._religiousPlaces.map(
              (place) =>
                  _ReligiousPlaceTile(
                place: place,
                onDirections: () =>
                    _openDirectionsToPlace(
                  place,
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            /// -----------------------------------------------------
            /// المدن العراقية
            /// -----------------------------------------------------

            const Text(
              'أو اختر نقطة انطلاق من المدن الرئيسية:',
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            ...iraqiCities
                .where(
                  (c) =>
                      c.name != 'كربلاء',
                )
                .map(
                  (city) =>
                      _CityDistanceTile(
                    city: city,
                    onDirections:
                        () =>
                            _openDirectionsFromCity(
                      city,
                    ),
                    roadDistanceCalculator:
                        _getRoadDistanceToShrine,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// بطاقة مكان ديني
/// ===============================================================

class _ReligiousPlaceTile
    extends StatelessWidget {
  final ReligiousPlace place;
  final VoidCallback onDirections;

  const _ReligiousPlaceTile({
    required this.place,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          place.icon,
          color: place.color,
        ),
        title: Text(
          place.name,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        subtitle: Text(
          place.country,
          style:
              const TextStyle(
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.directions,
            color: AppColors.gold,
          ),
          onPressed: onDirections,
        ),
      ),
    );
  }
}

/// ===============================================================
/// بطاقة المدينة
/// ===============================================================

class _CityDistanceTile
    extends StatefulWidget {
  final IraqiCity city;
  final VoidCallback onDirections;
  final Future<double> Function(
    double lat,
    double lng,
  ) roadDistanceCalculator;

  const _CityDistanceTile({
    required this.city,
    required this.onDirections,
    required this.roadDistanceCalculator,
  });

  @override
  State<_CityDistanceTile>
      createState() =>
          _CityDistanceTileState();
}

class _CityDistanceTileState
    extends State<_CityDistanceTile> {
  double? _roadDistance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoadDistance();
  }

  Future<void>
      _loadRoadDistance() async {
    try {
      final distance =
          await widget
              .roadDistanceCalculator(
        widget.city.lat,
        widget.city.lng,
      );

      if (!mounted) return;

      setState(() {
        _roadDistance =
            distance;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _roadDistance =
            widget.city
                .approxDistanceKm
                .toDouble();
        _loading = false;
      });
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.location_city,
          color:
              AppColors.primaryGreen,
        ),
        title: Text(
          widget.city.name,
        ),
        subtitle: _loading
            ? const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    'جاري حساب المسافة...',
                    style:
                        TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Text(
                'أقصر مسافة: ~'
                '${_roadDistance!.toStringAsFixed(0)} كم',
                style:
                    const TextStyle(
                  fontSize: 13,
                ),
              ),
        trailing:
            IconButton(
          icon: const Icon(
            Icons.directions,
            color: AppColors.gold,
          ),
          onPressed:
              widget.onDirections,
        ),
      ),
    );
  }
}
