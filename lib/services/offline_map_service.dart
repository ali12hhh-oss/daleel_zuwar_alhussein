import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة الخرائط المحلية:
/// 1) تخزين بلاطات OSM للاستخدام بدون إنترنت.
/// 2) حفظ المسارات التي حسبها محرك التوجيه الأونلاين لاستخدامها لاحقاً.
class OfflineMapService {
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> subdomains = <String>[];

  static const String _fallbackTileUrlTemplate =
      'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  static const String _routesKey = 'saved_route_options_v2';
  static String? _tilesDirPath;

  static Future<void> init() async {
    if (_tilesDirPath != null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/map_tiles');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _tilesDirPath = dir.path;
  }

  static (int, int) latLngToTile(double lat, double lng, int zoom) {
    final safeLat = lat.clamp(-85.05112878, 85.05112878).toDouble();
    final n = math.pow(2, zoom).toDouble();
    final x = ((lng + 180.0) / 360.0 * n).floor();
    final latRad = safeLat * math.pi / 180.0;
    final y = ((1.0 -
                    math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) /
                        math.pi) /
                2.0 *
            n)
        .floor();
    return (x.clamp(0, n.toInt() - 1), y.clamp(0, n.toInt() - 1));
  }

  static String? cachedTilePath(int z, int x, int y) {
    if (_tilesDirPath == null) return null;
    final path = '$_tilesDirPath/$z/$x/$y.png';
    if (File(path).existsSync()) return path;
    return null;
  }

  static Future<void> downloadRegion({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required int minZoom,
    required int maxZoom,
    required void Function(int downloaded, int total, int failed) onProgress,
    int concurrency = 6,
  }) async {
    await init();
    final dir = _tilesDirPath!;

    final tiles = <List<int>>[];
    for (int z = minZoom; z <= maxZoom; z++) {
      final topLeft = latLngToTile(maxLat, minLng, z);
      final bottomRight = latLngToTile(minLat, maxLng, z);
      for (int x = topLeft.$1; x <= bottomRight.$1; x++) {
        for (int y = topLeft.$2; y <= bottomRight.$2; y++) {
          tiles.add(<int>[z, x, y]);
        }
      }
    }

    final total = tiles.length;
    int downloaded = 0;
    int failed = 0;
    onProgress(0, total, 0);

    for (int i = 0; i < tiles.length; i += concurrency) {
      final batch = tiles.skip(i).take(concurrency);
      await Future.wait(batch.map((tile) async {
        final z = tile[0];
        final x = tile[1];
        final y = tile[2];
        final file = File('$dir/$z/$x/$y.png');

        if (await file.exists()) {
          downloaded++;
          return;
        }

        try {
          final url = tileUrlTemplate
              .replaceAll('{s}', '')
              .replaceAll('{z}', '$z')
              .replaceAll('{x}', '$x')
              .replaceAll('{y}', '$y')
              .replaceAll('{r}', '');

          var response = await http
              .get(Uri.parse(url), headers: const {'User-Agent': 'daleel-zuwar-alhussein/1.0'})
              .timeout(const Duration(seconds: 12));

          if (response.statusCode != 200) {
            final fallbackUrl = _fallbackTileUrlTemplate
                .replaceAll('{z}', '$z')
                .replaceAll('{x}', '$x')
                .replaceAll('{y}', '$y');
            response = await http
                .get(Uri.parse(fallbackUrl), headers: const {'User-Agent': 'daleel-zuwar-alhussein/1.0'})
                .timeout(const Duration(seconds: 12));
          }

          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            await file.parent.create(recursive: true);
            await file.writeAsBytes(response.bodyBytes, flush: true);
            downloaded++;
          } else {
            failed++;
          }
        } catch (_) {
          failed++;
        }
      }));
      onProgress(downloaded, total, failed);
    }
  }

  static Future<double> getCacheSizeMb() async {
    await init();
    final dir = Directory(_tilesDirPath!);
    if (!await dir.exists()) return 0;
    int totalBytes = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes / (1024 * 1024);
  }

  static Future<void> clearCache() async {
    if (_tilesDirPath == null) return;
    final dir = Directory(_tilesDirPath!);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await init();
  }

  /// يحفظ المسارات التي حسبها المحرك الأونلاين.
  /// تحفظ فقط الوجهة والمسارات، مع نقطة البداية التي حسبت منها.
  static Future<void> saveRoutes({
    required double latitude,
    required double longitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required String destinationName,
    required List<SavedRoute> routes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getStringList(_routesKey) ?? <String>[];

    final key = _routeSetKey(
      latitude,
      longitude,
      destinationLatitude,
      destinationLongitude,
      destinationName,
    );

    final records = <String, dynamic>{};
    for (final raw in old) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          records[decoded['key']?.toString() ?? ''] = decoded;
        }
      } catch (_) {}
    }

    records[key] = <String, dynamic>{
      'key': key,
      'latitude': latitude,
      'longitude': longitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
      'destinationName': destinationName,
      'routes': routes.map((route) => route.toJson()).toList(),
      'savedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setStringList(
      _routesKey,
      records.values.map((e) => jsonEncode(e)).toList(),
    );
  }

  /// يبحث عن آخر مجموعة مسارات محفوظة لهذه الوجهة.
  /// إذا لم يجد نقطة البداية نفسها تماماً، يبحث عن أقرب مجموعة محفوظة ضمن 2 كم.
  static Future<List<SavedRoute>> getSavedRoutes({
    required double destinationLatitude,
    required double destinationLongitude,
    required String destinationName,
    double? fromLatitude,
    double? fromLongitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getStringList(_routesKey) ?? <String>[];

    final candidates = <Map<String, dynamic>>[];
    for (final raw in old) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic> &&
            decoded['destinationName']?.toString() == destinationName) {
          final dLat = (decoded['destinationLatitude'] as num?)?.toDouble();
          final dLng = (decoded['destinationLongitude'] as num?)?.toDouble();
          if (dLat != null && dLng != null &&
              (dLat - destinationLatitude).abs() < 0.001 &&
              (dLng - destinationLongitude).abs() < 0.001) {
            candidates.add(decoded);
          }
        }
      } catch (_) {}
    }

    if (candidates.isEmpty) return <SavedRoute>[];

    Map<String, dynamic>? best;
    if (fromLatitude != null && fromLongitude != null) {
      double bestDistance = double.infinity;
      for (final candidate in candidates) {
        final lat = (candidate['latitude'] as num?)?.toDouble();
        final lng = (candidate['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        final d = _haversineKm(fromLatitude, fromLongitude, lat, lng);
        if (d < bestDistance) {
          bestDistance = d;
          best = candidate;
        }
      }
      if (best != null && bestDistance > 2.0) {
        return <SavedRoute>[];
      }
    } else {
      candidates.sort((a, b) =>
          (b['savedAt']?.toString() ?? '').compareTo(a['savedAt']?.toString() ?? ''));
      best = candidates.first;
    }

    best ??= candidates.first;
    final rawRoutes = best['routes'];
    if (rawRoutes is! List) return <SavedRoute>[];

    return rawRoutes
        .whereType<Map>()
        .map((raw) => SavedRoute.fromJson(Map<String, dynamic>.from(raw)))
        .toList();
  }

  static String _routeSetKey(
    double lat,
    double lng,
    double dLat,
    double dLng,
    String name,
  ) {
    return '${name}_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}_${dLat.toStringAsFixed(5)}_${dLng.toStringAsFixed(5)}';
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLon = (lon2 - lon1) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180.0) *
            math.cos(lat2 * math.pi / 180.0) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

class SavedRoute {
  final double distanceKm;
  final double durationMin;
  final List<LatLng> points;

  const SavedRoute({
    required this.distanceKm,
    required this.durationMin,
    required this.points,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'distanceKm': distanceKm,
        'durationMin': durationMin,
        'points': points
            .map((p) => <String, double>{'lat': p.latitude, 'lng': p.longitude})
            .toList(),
      };

  factory SavedRoute.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    final points = <LatLng>[];
    if (rawPoints is List) {
      for (final raw in rawPoints) {
        if (raw is Map) {
          final lat = (raw['lat'] as num?)?.toDouble();
          final lng = (raw['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            points.add(LatLng(lat, lng));
          }
        }
      }
    }
    return SavedRoute(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      durationMin: (json['durationMin'] as num?)?.toDouble() ?? 0,
      points: points,
    );
  }
}

/// مزود يستخدم الذاكرة المحلية أولاً، ثم الإنترنت عند عدم وجود البلاطة.
class OfflineFirstTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final z = coordinates.z.toInt();
    final x = coordinates.x.toInt();
    final y = coordinates.y.toInt();
    final cachedPath = OfflineMapService.cachedTilePath(z, x, y);
    if (cachedPath != null) return FileImage(File(cachedPath));

    final subdomains = options.subdomains;
    final subdomain = subdomains.isNotEmpty
        ? subdomains[(x + y) % subdomains.length]
        : '';
    final url = options.urlTemplate!
        .replaceAll('{s}', subdomain)
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y')
        .replaceAll('{r}', '');
    return NetworkImage(url);
  }
}

/// مزود أوفلاين حقيقي: لا يحاول الاتصال بالشبكة أبداً.
/// عند عدم وجود البلاطة يعرض صورة شفافة بسيطة بدلاً من طلبها من الإنترنت.
class OfflineOnlyTileProvider extends TileProvider {
  static final List<int> _transparentPng = <int>[
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0,
    0, 11, 73, 68, 65, 84, 8, 215, 99, 0, 1, 0, 0, 5, 0, 1, 13,
    10, 42, 184, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
  ];

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final z = coordinates.z.toInt();
    final x = coordinates.x.toInt();
    final y = coordinates.y.toInt();
    final cachedPath = OfflineMapService.cachedTilePath(z, x, y);
    if (cachedPath != null) return FileImage(File(cachedPath));
    return MemoryImage(_transparentPng);
  }
}
