import 'dart:convert';
import 'dart:math';

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

/// ===============================================================
/// الوجهات المقدسة
///
/// لم تعد الخريطة مرتبطة بالعراق فقط.
/// يمكن إضافة أي مرقد أو مسجد أو مقبرة أو مقام هنا.
/// ===============================================================

class SacredDestination {
  final String name;
  final String subtitle;
  final String type;
  final double lat;
  final double lng;

  const SacredDestination({
    required this.name,
    required this.subtitle,
    required this.type,
    required this.lat,
    required this.lng,
  });
}

/// ===============================================================
/// قائمة الوجهات
/// ===============================================================

const List<SacredDestination> sacredDestinations = [
  SacredDestination(
    name: 'مرقد الإمام الحسين (ع)',
    subtitle: 'كربلاء المقدسة - العراق',
    type: 'مرقد',
    lat: 32.6163,
    lng: 44.0326,
  ),

  SacredDestination(
    name: 'مرقد الإمام علي (ع)',
    subtitle: 'النجف الأشرف - العراق',
    type: 'مرقد',
    lat: 31.9960,
    lng: 44.3143,
  ),

  SacredDestination(
    name: 'مسجد الكوفة الأعظم',
    subtitle: 'الكوفة - النجف - العراق',
    type: 'مسجد',
    lat: 32.02906,
    lng: 44.40120,
  ),

  SacredDestination(
    name: 'مسجد السهلة المعظم',
    subtitle: 'الكوفة - النجف - العراق',
    type: 'مسجد',
    lat: 32.03897,
    lng: 44.37975,
  ),

  SacredDestination(
    name: 'مقبرة وادي السلام',
    subtitle: 'النجف الأشرف - العراق',
    type: 'مقبرة',
    lat: 32.0235,
    lng: 44.30218,
  ),

  SacredDestination(
    name: 'مرقد الإمامين الكاظم والجواد (ع)',
    subtitle: 'الكاظمية - بغداد - العراق',
    type: 'مرقد',
    lat: 33.38003,
    lng: 44.33810,
  ),

  SacredDestination(
    name: 'مرقد الإمامين الهادي والعسكري (ع)',
    subtitle: 'سامراء - العراق',
    type: 'مرقد',
    lat: 34.19893,
    lng: 43.87353,
  ),

  SacredDestination(
    name: 'سرداب الغيبة',
    subtitle: 'سامراء - العراق',
    type: 'مقام',
    lat: 34.19893,
    lng: 43.87353,
  ),

  SacredDestination(
    name: 'المسجد النبوي الشريف',
    subtitle: 'المدينة المنورة - السعودية',
    type: 'مسجد',
    lat: 24.46865,
    lng: 39.61117,
  ),

  SacredDestination(
    name: 'البقيع الشريف',
    subtitle: 'المدينة المنورة - السعودية',
    type: 'مقبرة',
    lat: 24.46667,
    lng: 39.61633,
  ),

  SacredDestination(
    name: 'مرقد الإمام الرضا (ع)',
    subtitle: 'مشهد المقدسة - إيران',
    type: 'مرقد',
    lat: 36.28797,
    lng: 59.61569,
  ),

  SacredDestination(
    name: 'مرقد السيدة زينب (ع)',
    subtitle: 'السيدة زينب - ريف دمشق - سوريا',
    type: 'مرقد',
    lat: 33.44444,
    lng: 36.34083,
  ),
];

/// ===============================================================
/// خيار طريق واحد
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
/// شاشة الخرائط
/// ===============================================================

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  // =============================================================
  // الحالة
  // =============================================================

  bool _loading = false;
  String? _error;

  Position? _position;
  IraqiCity? _nearestCity;

  double? _straightDistanceKm;
  double? _roadDistanceKm;

  double? _roadDurationMin;

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

  SacredDestination _selectedDestination =
      sacredDestinations.first;

  // =============================================================
  // مركز افتراضي عالمي
  // =============================================================

  static const double defaultLat = 30.0;
  static const double defaultLng = 45.0;

  // =============================================================
  // خريطة OpenStreetMap
  // =============================================================

  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // =============================================================
  // بداية الشاشة
  // =============================================================

  @override
  void initState() {
    super.initState();

    _initMapAndCache();
    _detectLocation();
  }

  // =============================================================
  // تهيئة الخرائط
  // =============================================================

  Future<void> _initMapAndCache() async {
    try {
      await OfflineMapService.init();
      await _loadCachedSize();
    } catch (_) {
      // لا نوقف التطبيق بسبب فشل التخزين المؤقت.
    }
  }

  Future<void> _loadCachedSize() async {
    try {
      final size =
          await OfflineMapService.getCacheSizeMb();

      if (!mounted) return;

      setState(() {
        _cachedSizeMb = size > 0 ? size : null;
      });
    } catch (_) {}
  }

  // =============================================================
  // حساب المسافة الجوية
  // =============================================================

  double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const radius = 6371.0;

    final dLat =
        _deg2rad(lat2 - lat1);

    final dLon =
        _deg2rad(lon2 - lon1);

    final a =
        sin(dLat / 2) *
                sin(dLat / 2) +
            cos(_deg2rad(lat1)) *
                cos(_deg2rad(lat2)) *
                sin(dLon / 2) *
                sin(dLon / 2);

    final c =
        2 *
        atan2(
          sqrt(a),
          sqrt(1 - a),
        );

    return radius * c;
  }

  double _deg2rad(double deg) {
    return deg * pi / 180;
  }

  // =============================================================
  // جلب المسارات
  //
  // ملاحظة:
  // خادم OSRM العام مناسب أساساً لمسارات القيادة.
  // لذلك نستخدم driving هنا كمسار بري رئيسي.
  // =============================================================

  Future<List<RouteOption>> _fetchRoutes({
    required double fromLat,
    required double fromLng,
    required String profile,
  }) async {
    try {
      final destination =
          _selectedDestination;

      final url =
          'https://router.project-osrm.org/route/v1/'
          '$profile/'
          '$fromLng,$fromLat;'
          '${destination.lng},${destination.lat}'
          '?overview=full'
          '&geometries=geojson'
          '&alternatives=true'
          '&steps=false';

      final response = await http
          .get(Uri.parse(url))
          .timeout(
            const Duration(seconds: 25),
          );

      if (response.statusCode != 200) {
        return [];
      }

      final data =
          jsonDecode(response.body);

      final rawRoutes =
          data['routes'];

      if (rawRoutes is! List ||
          rawRoutes.isEmpty) {
        return [];
      }

      final result =
          <RouteOption>[];

      for (final rawRoute
          in rawRoutes) {
        if (rawRoute is! Map) {
          continue;
        }

        final distance =
            (rawRoute['distance'] as num?)
                ?.toDouble();

        final duration =
            (rawRoute['duration'] as num?)
                ?.toDouble();

        final geometry =
            rawRoute['geometry'];

        if (distance == null ||
            duration == null ||
            geometry is! Map) {
          continue;
        }

        final coordinates =
            geometry['coordinates'];

        if (coordinates is! List ||
            coordinates.isEmpty) {
          continue;
        }

        final points =
            <LatLng>[];

        for (final coordinate
            in coordinates) {
          if (coordinate is! List ||
              coordinate.length < 2) {
            continue;
          }

          final lng =
              (coordinate[0] as num)
                  .toDouble();

          final lat =
              (coordinate[1] as num)
                  .toDouble();

          points.add(
            LatLng(lat, lng),
          );
        }

        if (points.length < 2) {
          continue;
        }

        result.add(
          RouteOption(
            distanceKm:
                distance / 1000,
            durationMin:
                duration / 60,
            points: points,
            profile: profile,
          ),
        );
      }

      return result;
    } catch (_) {
      return [];
    }
  }

  // =============================================================
  // حساب المسارات
  // =============================================================

  Future<void> _calculateRoadDistance() async {
    if (_position == null) return;

    if (mounted) {
      setState(() {
        _calculatingRoute = true;
        _routeOptions = [];
        _routePoints = [];
        _roadDistanceKm = null;
        _roadDurationMin = null;
      });
    }

    final options =
        <RouteOption>[];

    // -------------------------------------------------------------
    // مسارات السيارة
    // -------------------------------------------------------------

    final drivingOptions =
        await _fetchRoutes(
      fromLat: _position!.latitude,
      fromLng: _position!.longitude,
      profile: 'driving',
    );

    options.addAll(
      drivingOptions,
    );

    // -------------------------------------------------------------
    // محاولة مسار المشي
    //
    // إذا لم يدعم الخادم الملف، سيتم تجاهله.
    // -------------------------------------------------------------

    final footOptions =
        await _fetchRoutes(
      fromLat: _position!.latitude,
      fromLng: _position!.longitude,
      profile: 'foot',
    );

    options.addAll(
      footOptions,
    );

    if (!mounted) return;

    // -------------------------------------------------------------
    // لا يوجد طريق
    // -------------------------------------------------------------

    if (options.isEmpty) {
      setState(() {
        _calculatingRoute = false;
        _roadDistanceKm =
            _straightDistanceKm;
        _roadDurationMin = null;
      });

      return;
    }

    // -------------------------------------------------------------
    // الأقصر
    // -------------------------------------------------------------

    int shortestIndex = 0;

    double shortestDistance =
        options.first.distanceKm;

    for (int i = 1;
        i < options.length;
        i++) {
      if (options[i].distanceKm <
          shortestDistance) {
        shortestDistance =
            options[i].distanceKm;

        shortestIndex = i;
      }
    }

    final shortest =
        options[shortestIndex];

    setState(() {
      _routeOptions = options;

      _selectedRouteIndex =
          shortestIndex;

      _roadDistanceKm =
          shortest.distanceKm;

      _roadDurationMin =
          shortest.durationMin;

      _routePoints =
          shortest.points;

      _calculatingRoute = false;
    });
  }

  // =============================================================
  // اختيار مسار
  // =============================================================

  void _selectRoute(int index) {
    if (index < 0 ||
        index >= _routeOptions.length) {
      return;
    }

    final route =
        _routeOptions[index];

    setState(() {
      _selectedRouteIndex = index;

      _roadDistanceKm =
          route.distanceKm;

      _roadDurationMin =
          route.durationMin;

      _routePoints =
          route.points;
    });
  }

  // =============================================================
  // مسافة مدينة إلى الوجهة الحالية
  // =============================================================

  Future<double> _getRoadDistanceFromCity(
    double lat,
    double lng,
  ) async {
    final options =
        await _fetchRoutes(
      fromLat: lat,
      fromLng: lng,
      profile: 'driving',
    );

    if (options.isNotEmpty) {
      options.sort(
        (a, b) =>
            a.distanceKm.compareTo(
          b.distanceKm,
        ),
      );

      return options.first.distanceKm;
    }

    return _haversineKm(
          lat,
          lng,
          _selectedDestination.lat,
          _selectedDestination.lng,
        ) *
        1.3;
  }

  // =============================================================
  // تحديد الموقع
  // =============================================================

  Future<void> _detectLocation() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'يرجى تفعيل خدمة الموقع GPS.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator
                .requestPermission();

        if (permission ==
            LocationPermission.denied) {
          throw Exception(
            'تم رفض إذن الوصول إلى الموقع.',
          );
        }
      }

      if (permission ==
          LocationPermission.deniedForever) {
        throw Exception(
          'إذن الموقع مرفوض بشكل دائم. يرجى السماح به من إعدادات الهاتف.',
        );
      }

      final pos =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      // -----------------------------------------------------------
      // أقرب مدينة عراقية
      // -----------------------------------------------------------

      IraqiCity? nearest;

      double minDistance =
          double.infinity;

      for (final city
          in iraqiCities) {
        final distance =
            _haversineKm(
          pos.latitude,
          pos.longitude,
          city.lat,
          city.lng,
        );

        if (distance <
            minDistance) {
          minDistance =
              distance;

          nearest = city;
        }
      }

      // -----------------------------------------------------------
      // المسافة إلى الوجهة المختارة
      // -----------------------------------------------------------

      final distanceToDestination =
          _haversineKm(
        pos.latitude,
        pos.longitude,
        _selectedDestination.lat,
        _selectedDestination.lng,
      );

      if (!mounted) return;

      setState(() {
        _position = pos;

        _nearestCity = nearest;

        _straightDistanceKm =
            distanceToDestination;

        _loading = false;
      });

      await _calculateRoadDistance();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );

        _loading = false;
      });
    }
  }

  // =============================================================
  // اختيار الوجهة
  // =============================================================

  Future<void> _selectDestination(
    SacredDestination destination,
  ) async {
    setState(() {
      _selectedDestination =
          destination;

      _routeOptions = [];
      _routePoints = [];
      _roadDistanceKm = null;
      _roadDurationMin = null;
      _calculatingRoute = false;
    });

    if (_position != null) {
      final distance =
          _haversineKm(
        _position!.latitude,
        _position!.longitude,
        destination.lat,
        destination.lng,
      );

      setState(() {
        _straightDistanceKm =
            distance;
      });

      await _calculateRoadDistance();
    }
  }

  // =============================================================
  // فتح Google Maps
  // =============================================================

  Future<void> _openDirections() async {
    if (_position == null) {
      return;
    }

    final destination =
        _selectedDestination;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_position!.latitude},${_position!.longitude}'
      '&destination=${destination.lat},${destination.lng}'
      '&travelmode=driving',
    );

    final launched =
        await launchUrl(
      uri,
      mode:
          LaunchMode.externalApplication,
    );

    if (!launched &&
        mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'تعذّر فتح تطبيق الخرائط.',
          ),
        ),
      );
    }
  }

  // =============================================================
  // فتح الاتجاهات من مدينة
  // =============================================================

  Future<void> _openDirectionsFromCity(
    IraqiCity city,
  ) async {
    final destination =
        _selectedDestination;

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${city.lat},${city.lng}'
      '&destination=${destination.lat},${destination.lng}'
      '&travelmode=driving',
    );

    final launched =
        await launchUrl(
      uri,
      mode:
          LaunchMode.externalApplication,
    );

    if (!launched &&
        mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'تعذّر فتح تطبيق الخرائط.',
          ),
        ),
      );
    }
  }

  // =============================================================
  // تحميل خريطة منطقة الوجهة
  //
  // لم تعد محصورة بالعراق.
  // =============================================================

  Future<void> _cacheDestinationMap() async {
    final destination =
        _selectedDestination;

    setState(() {
      _isCaching = true;

      _downloadedTiles = 0;

      _totalTiles = 0;

      _cacheStatus =
          'جاري تجهيز خريطة ${destination.name}...';
    });

    try {
      // -----------------------------------------------------------
      // منطقة صغيرة حول الوجهة
      //
      // يمكن تكبيرها لاحقاً حسب الحاجة.
      // -----------------------------------------------------------

      const delta = 0.35;

      await OfflineMapService
          .downloadRegion(
        minLat:
            destination.lat - delta,
        maxLat:
            destination.lat + delta,
        minLng:
            destination.lng - delta,
        maxLng:
            destination.lng + delta,
        minZoom: 10,
        maxZoom: 15,
        onProgress:
            (
          downloaded,
          total,
          failed,
        ) {
          if (!mounted) return;

          setState(() {
            _downloadedTiles =
                downloaded;

            _totalTiles =
                total;

            _cacheStatus =
                'جاري تحميل ${destination.name}: '
                '$downloaded من $total';
          });
        },
      );

      final sizeMb =
          await OfflineMapService
              .getCacheSizeMb();

      if (!mounted) return;

      setState(() {
        _isCaching = false;

        _cachedSizeMb = sizeMb;

        _cacheStatus =
            'تم تحميل منطقة ${destination.name} '
            'للاستخدام بدون إنترنت '
            '(${sizeMb.toStringAsFixed(1)} م.ب)';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isCaching = false;

        _cacheStatus =
            'فشل تحميل الخريطة. '
            'تأكد من الاتصال بالإنترنت وحاول مرة أخرى.';
      });
    }
  }

  // =============================================================
  // اسم المسار
  // =============================================================

  String _routeLabel(
    RouteOption option,
    int index,
  ) {
    final sameType =
        _routeOptions
            .where(
              (route) =>
                  route.profile ==
                  option.profile,
            )
            .toList();

    final type =
        option.profile == 'foot'
            ? '🚶 مشي'
            : '🚗 سيارة';

    if (sameType.length > 1) {
      final typeIndex =
          sameType.indexOf(option) + 1;

      return '$type $typeIndex';
    }

    return type;
  }

  // =============================================================
  // أيقونة الوجهة
  // =============================================================

  IconData _destinationIcon(
    SacredDestination destination,
  ) {
    switch (destination.type) {
      case 'مسجد':
        return Icons.mosque;

      case 'مقبرة':
        return Icons.account_balance;

      case 'مقام':
        return Icons.place;

      case 'مرقد':
      default:
        return Icons.mosque;
    }
  }

  // =============================================================
  // حساب وقت المشي التقريبي
  // =============================================================

  String _walkingTime(
    double distanceKm,
  ) {
    const walkingSpeed =
        5.0; // km/h

    final hours =
        distanceKm /
        walkingSpeed;

    final totalMinutes =
        (hours * 60).round();

    if (totalMinutes < 60) {
      return '$totalMinutes دقيقة تقريباً';
    }

    final h =
        totalMinutes ~/ 60;

    final m =
        totalMinutes % 60;

    if (m == 0) {
      return '$h ساعة تقريباً';
    }

    return '$h ساعة و$m دقيقة تقريباً';
  }

  // =============================================================
  // Build
  // =============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دليل المراقد والأماكن المقدسة',
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _detectLocation,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(16),
          children: [
            _buildDestinationSelector(),

            const SizedBox(height: 16),

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

            if (_error != null)
              _buildError(),

            if (_position != null &&
                _straightDistanceKm != null)
              _buildDistanceCard(),

            const SizedBox(height: 16),

            _buildMapCard(),

            if (_showMap) ...[
              const SizedBox(height: 16),
              _buildMap(),
            ],

            const SizedBox(height: 20),

            _buildCitiesSection(),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // اختيار الوجهة
  // =============================================================

  Widget _buildDestinationSelector() {
    return Card(
      elevation: 3,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Text(
              'اختر المكان المقدس',
              textDirection:
                  TextDirection.rtl,
              textAlign:
                  TextAlign.right,
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'يمكنك اختيار وجهة داخل العراق أو خارجه.',
              textDirection:
                  TextDirection.rtl,
              textAlign:
                  TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color:
                    Colors.black54,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<
                SacredDestination>(
              initialValue:
                  _selectedDestination,
              isExpanded: true,
              decoration:
                  InputDecoration(
                filled: true,
                fillColor:
                    Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              items:
                  sacredDestinations.map(
                (destination) {
                  return DropdownMenuItem<
                      SacredDestination>(
                    value:
                        destination,
                    child: Row(
                      children: [
                        Icon(
                          _destinationIcon(
                            destination,
                          ),
                          color:
                              AppColors
                                  .primaryGreen,
                          size: 23,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            destination
                                .name,
                            textDirection:
                                TextDirection
                                    .rtl,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
              onChanged:
                  (destination) {
                if (destination !=
                    null) {
                  _selectDestination(
                    destination,
                  );
                }
              },
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Icon(
                  _destinationIcon(
                    _selectedDestination,
                  ),
                  color:
                      AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${_selectedDestination.type}: '
                    '${_selectedDestination.subtitle}',
                    textDirection:
                        TextDirection.rtl,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // بطاقة المسافة
  // =============================================================

  Widget _buildDistanceCard() {
    return Card(
      color:
          AppColors.primaryGreen,
      child: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _destinationIcon(
                _selectedDestination,
              ),
              color: Colors.white,
              size: 36,
            ),

            const SizedBox(height: 8),

            Text(
              _selectedDestination.name,
              textDirection:
                  TextDirection.rtl,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              _selectedDestination.subtitle,
              textDirection:
                  TextDirection.rtl,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 12),

            if (_nearestCity != null)
              Text(
                'أقرب مدينة عراقية معروفة: '
                '${_nearestCity!.name}',
                textDirection:
                    TextDirection.rtl,
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),

            const SizedBox(height: 8),

            Text(
              'المسافة المستقيمة: '
              '${_straightDistanceKm!.toStringAsFixed(1)} كم',
              style:
                  const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),

            if (_calculatingRoute) ...[
              const SizedBox(height: 10),

              const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
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
                  SizedBox(width: 8),
                  Text(
                    'جاري البحث عن المسارات...',
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
              const SizedBox(height: 10),

              Text(
                'أقصر مسار بري: '
                '${_roadDistanceKm!.toStringAsFixed(1)} كم',
                style:
                    const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              if (_roadDurationMin !=
                  null)
                Text(
                  'مدة القيادة التقريبية: '
                  '${_formatDuration(_roadDurationMin!)}',
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 12,
                  ),
                ),

              const SizedBox(height: 4),

              Text(
                'وقت المشي التقريبي: '
                '${_walkingTime(_roadDistanceKm!)}',
                style:
                    const TextStyle(
                  color:
                      Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],

            if (_routeOptions.length >
                1) ...[
              const SizedBox(height: 14),

              const Text(
                'المسارات المتاحة:',
                textDirection:
                    TextDirection.rtl,
                style:
                    TextStyle(
                  color:
                      Colors.white70,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment:
                    WrapAlignment.center,
                children:
                    List.generate(
                  _routeOptions.length,
                  (i) {
                    final option =
                        _routeOptions[i];

                    final selected =
                        i ==
                            _selectedRouteIndex;

                    final shortest =
                        _routeOptions
                            .map(
                              (e) =>
                                  e.distanceKm,
                            )
                            .reduce(min);

                    final isShortest =
                        option.distanceKm ==
                            shortest;

                    return ChoiceChip(
                      label: Text(
                        '${_routeLabel(option, i)} '
                        '• ${option.distanceKm.toStringAsFixed(1)} كم'
                        '${isShortest ? ' ⭐' : ''}',
                        style:
                            TextStyle(
                          fontSize: 11,
                          color:
                              selected
                                  ? Colors.white
                                  : Colors.black87,
                        ),
                      ),
                      selected:
                          selected,
                      selectedColor:
                          AppColors.gold,
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

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed:
                  _openDirections,
              icon: const Icon(
                Icons.directions,
              ),
              label: const Text(
                'فتح الطريق في الخرائط',
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.gold,
                foregroundColor:
                    Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // تنسيق المدة
  // =============================================================

  String _formatDuration(
    double minutes,
  ) {
    final total =
        minutes.round();

    if (total < 60) {
      return '$total دقيقة تقريباً';
    }

    final hours =
        total ~/ 60;

    final remaining =
        total % 60;

    if (remaining == 0) {
      return '$hours ساعة تقريباً';
    }

    return '$hours ساعة و$remaining دقيقة تقريباً';
  }

  // =============================================================
  // بطاقة الخريطة
  // =============================================================

  Widget _buildMapCard() {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.map,
                  color:
                      AppColors.primaryGreen,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'الخريطة العالمية والطرق',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showMap =
                        !_showMap;
                  });
                },
                icon: Icon(
                  _showMap
                      ? Icons.map_outlined
                      : Icons.map,
                ),
                label: Text(
                  _showMap
                      ? 'إخفاء الخريطة'
                      : 'عرض الخريطة',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors
                          .primaryGreen,
                  foregroundColor:
                      Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    _isCaching
                        ? null
                        : _cacheDestinationMap,
                icon: _isCaching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.download,
                      ),
                label: Text(
                  _isCaching
                      ? 'جاري تحميل المنطقة...'
                      : 'تحميل منطقة الوجهة بدون إنترنت',
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blue,
                  foregroundColor:
                      Colors.white,
                ),
              ),
            ),

            if (_isCaching &&
                _totalTiles > 0) ...[
              const SizedBox(height: 10),

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
                child:
                    LinearProgressIndicator(
                  value:
                      _downloadedTiles /
                          _totalTiles,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${((_downloadedTiles / _totalTiles) * 100).toStringAsFixed(0)}%',
                style:
                    const TextStyle(
                  fontSize: 11,
                ),
              ),
            ],

            if (_cachedSizeMb !=
                    null &&
                !_isCaching)
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 8,
                ),
                child: Text(
                  'حجم الخرائط المخزنة: '
                  '${_cachedSizeMb!.toStringAsFixed(1)} م.ب',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color:
                        Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),

            if (_cacheStatus
                .isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.only(
                  top: 8,
                ),
                child: Text(
                  _cacheStatus,
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        _cacheStatus
                                .contains(
                              'تم',
                            )
                            ? Colors
                                .green
                            : _cacheStatus
                                    .contains(
                                  'فشل',
                                )
                                ? Colors
                                    .red
                                : Colors
                                    .orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // الخريطة
  // =============================================================

  Widget _buildMap() {
    final destination =
        _selectedDestination;

    final center =
        _position != null
            ? LatLng(
                _position!.latitude,
                _position!.longitude,
              )
            : LatLng(
                destination.lat,
                destination.lng,
              );

    return Card(
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(12),
        child: SizedBox(
          height: 560,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom:
                  _position != null
                      ? 7.0
                      : 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    _tileUrl,
                subdomains:
                    const [],
                userAgentPackageName:
                    'com.daleelzuwar.alhussein',
                tileProvider:
                    OfflineFirstTileProvider(),
              ),

              // ---------------------------------------------------
              // المسارات غير المختارة
              // ---------------------------------------------------

              if (_routeOptions
                  .isNotEmpty)
                PolylineLayer(
                  polylines: [
                    for (
                      int i = 0;
                      i <
                          _routeOptions
                              .length;
                      i++
                    )
                      if (i !=
                          _selectedRouteIndex)
                        Polyline(
                          points:
                              _routeOptions[
                                  i]
                              .points,
                          color: Colors
                              .grey
                              .withOpacity(
                            0.45,
                          ),
                          strokeWidth: 3,
                        ),

                    // المسار المختار
                    Polyline(
                      points:
                          _routeOptions[
                              _selectedRouteIndex]
                          .points,
                      color:
                          _routeOptions[
                                      _selectedRouteIndex]
                                  .profile ==
                              'foot'
                              ? AppColors
                                  .primaryGreen
                              : Colors.blue,
                      strokeWidth: 5,
                      borderStrokeWidth:
                          2,
                      borderColor:
                          Colors.white,
                    ),
                  ],
                ),

              // ---------------------------------------------------
              // خط مباشر إذا لم يوجد مسار
              // ---------------------------------------------------

              if (_routeOptions
                      .isEmpty &&
                  _position != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [
                        LatLng(
                          _position!
                              .latitude,
                          _position!
                              .longitude,
                        ),
                        LatLng(
                          destination.lat,
                          destination.lng,
                        ),
                      ],
                      color:
                          Colors.grey,
                      strokeWidth: 3,
                      strokeCap:
                          StrokeCap.round,
                    ),
                  ],
                ),

              // ---------------------------------------------------
              // العلامات
              // ---------------------------------------------------

              MarkerLayer(
                markers: [
                  // الوجهة
                  Marker(
                    point: LatLng(
                      destination.lat,
                      destination.lng,
                    ),
                    width: 110,
                    height: 75,
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          _destinationIcon(
                            destination,
                          ),
                          color:
                              AppColors
                                  .primaryGreen,
                          size: 36,
                        ),
                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                AppColors
                                    .primaryGreen,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              5,
                            ),
                          ),
                          child:
                              Text(
                            destination.name,
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // موقع المستخدم
                  if (_position !=
                      null)
                    Marker(
                      point: LatLng(
                        _position!
                            .latitude,
                        _position!
                            .longitude,
                      ),
                      width: 70,
                      height: 55,
                      child: Column(
                        children: [
                          const Icon(
                            Icons
                                .person_pin_circle,
                            color:
                                Colors.blue,
                            size: 34,
                          ),
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.blue,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                4,
                              ),
                            ),
                            child:
                                const Text(
                              'أنت هنا',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // المدن العراقية
                  ..._getRouteCities()
                      .map(
                    (city) => Marker(
                      point: LatLng(
                        city.lat,
                        city.lng,
                      ),
                      width: 40,
                      height: 40,
                      child: Tooltip(
                        message:
                            city.name,
                        child: Icon(
                          Icons
                              .location_city,
                          color: Colors
                              .orange
                              .shade700,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // المدن
  // =============================================================

  Widget _buildCitiesSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'أو اختر نقطة انطلاق من المدن العراقية:',
          textDirection:
              TextDirection.rtl,
          style:
              TextStyle(
            fontWeight:
                FontWeight.bold,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 8),

        ...iraqiCities
            .where(
              (city) =>
                  city.name !=
                  'كربلاء',
            )
            .map(
          (city) =>
              _CityDistanceTile(
            city: city,
            destination:
                _selectedDestination,
            onDirections:
                () =>
                    _openDirectionsFromCity(
                  city,
                ),
            roadDistanceCalculator:
                _getRoadDistanceFromCity,
          ),
        ),
      ],
    );
  }

  // =============================================================
  // مدن العراق التي تظهر على الخريطة
  // =============================================================

  List<IraqiCity> _getRouteCities() {
    const routeCities = [
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

    return iraqiCities
        .where(
          (city) =>
              routeCities.contains(
            city.name,
          ),
        )
        .toList();
  }

  // =============================================================
  // الخطأ
  // =============================================================

  Widget _buildError() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.location_off,
              color: Colors.red,
              size: 40,
            ),

            const SizedBox(height: 8),

            Text(
              _error!,
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 10),

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
    );
  }
}

/// ===============================================================
/// بطاقة المدينة
/// ===============================================================

class _CityDistanceTile
    extends StatefulWidget {
  final IraqiCity city;

  final SacredDestination
      destination;

  final VoidCallback onDirections;

  final Future<double>
      Function(
    double lat,
    double lng,
  ) roadDistanceCalculator;

  const _CityDistanceTile({
    required this.city,
    required this.destination,
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

  @override
  void didUpdateWidget(
    covariant _CityDistanceTile oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.destination !=
        widget.destination) {
      _roadDistance = null;

      _loading = true;

      _loadRoadDistance();
    }
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

      final fallback =
          _haversine(
        widget.city.lat,
        widget.city.lng,
        widget.destination.lat,
        widget.destination.lng,
      );

      setState(() {
        _roadDistance =
            fallback * 1.3;

        _loading = false;
      });
    }
  }

  double _haversine(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const r = 6371.0;

    final dLat =
        (lat2 - lat1) *
        pi /
        180;

    final dLng =
        (lng2 - lng1) *
        pi /
        180;

    final a =
        sin(dLat / 2) *
                sin(dLat / 2) +
            cos(
              lat1 * pi / 180,
            ) *
                cos(
                  lat2 * pi / 180,
                ) *
                sin(dLng / 2) *
                sin(dLng / 2);

    return r *
        2 *
        atan2(
          sqrt(a),
          sqrt(1 - a),
        );
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
                  SizedBox(width: 8),
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
                'إلى ${widget.destination.name}: '
                '~${_roadDistance!.toStringAsFixed(0)} كم',
                style:
                    const TextStyle(
                  fontSize: 12,
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
