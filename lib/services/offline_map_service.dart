import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// خدمة تحميل بلاطات الخريطة (map tiles) وتخزينها محلياً على الجهاز،
/// لتشتغل الخريطة بدون إنترنت بعد أول تحميل. لا تعتمد على أي مكتبة
/// خارجية إضافية (فقط http و path_provider الموجودتان أصلاً بالمشروع)
/// تجنباً لمشاكل تراخيص بعض مكتبات الخرائط الأوفلاين الجاهزة (GPL).
class OfflineMapService {
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> subdomains = [];

  /// ترويسة User-Agent مطلوبة إلزامياً حسب سياسة استخدام خرائط
  /// OpenStreetMap (https://operations.osmfoundation.org/policies/tiles/).
  /// بدونها تُصنَّف الطلبات كمشبوهة وتُحظر أو تُبطَّأ من طرف الخادم،
  /// مما يسبب ظهور بلاطات فارغة أو رمادية (جودة خريطة سيئة).
  static const Map<String, String> _tileHeaders = {
    'User-Agent': 'DaleelZuwarAlHussein/1.0 (Flutter app; contact via app)',
  };

  static String? _tilesDirPath;
  static bool _initializing = false;

  /// يجب استدعاؤها (ومنتظرة بـ await) مرة واحدة قبل استخدام الخريطة أو
  /// قراءة حجم التخزين المؤقت، لضمان عدم قراءة قيمة خاطئة (0) بسبب
  /// عدم اكتمال تهيئة مسار المجلد بعد.
  static Future<void> init() async {
    if (_tilesDirPath != null) return;
    if (_initializing) {
      // تجنّب تنفيذ التهيئة أكثر من مرة بالتوازي إذا استُدعيت من أكثر
      // من مكان بنفس الوقت
      while (_initializing) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
      return;
    }
    _initializing = true;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/map_tiles');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _tilesDirPath = dir.path;
    _initializing = false;
  }

  /// يحوّل إحداثيات (خط عرض/طول) إلى رقم بلاطة X وY عند مستوى تكبير معيّن
  /// (معادلة Slippy Map القياسية المستخدمة في كل خرائط الويب)
  static (int, int) latLngToTile(double lat, double lng, int zoom) {
    final n = math.pow(2, zoom).toDouble();
    final x = ((lng + 180.0) / 360.0 * n).floor();
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 -
                    math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) /
                        math.pi) /
                2.0 *
            n)
        .floor();
    return (x, y);
  }

  /// يتحقق إذا كانت بلاطة معيّنة محفوظة محلياً، ويرجع مسارها إن وُجدت
  static String? cachedTilePath(int z, int x, int y) {
    if (_tilesDirPath == null) return null;
    final path = '$_tilesDirPath/$z/$x/$y.png';
    if (File(path).existsSync()) return path;
    return null;
  }

  /// يحمّل كل بلاطات منطقة جغرافية (مربع إحداثيات) ضمن نطاق مستويات
  /// تكبير معيّن، ويخزّنها محلياً. onProgress يُستدعى بعد كل دفعة تحميل.
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
          tiles.add([z, x, y]);
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
        final z = tile[0], x = tile[1], y = tile[2];
        final file = File('$dir/$z/$x/$y.png');
        if (await file.exists()) {
          downloaded++;
          return;
        }
        try {
          final subdomain = subdomains.isNotEmpty
              ? subdomains[(x + y) % subdomains.length]
              : '';
          final url = tileUrlTemplate
              .replaceAll('{s}', subdomain)
              .replaceAll('{z}', '$z')
              .replaceAll('{x}', '$x')
              .replaceAll('{y}', '$y')
              .replaceAll('{r}', '');
          final response = await http
              .get(Uri.parse(url), headers: _tileHeaders)
              .timeout(const Duration(seconds: 12));
          if (response.statusCode == 200) {
            await file.parent.create(recursive: true);
            await file.writeAsBytes(response.bodyBytes);
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

  /// الحجم التقريبي للبلاطات المحفوظة بالميجابايت.
  /// تنتظر اكتمال init() أولاً لتفادي إرجاع 0 خطأً قبل معرفة مسار
  /// مجلد التخزين الفعلي.
  static Future<double> getCacheSizeMb() async {
    await init();
    if (_tilesDirPath == null) return 0;
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

  /// حذف كل البلاطات المحفوظة محلياً
  static Future<void> clearCache() async {
    if (_tilesDirPath == null) return;
    final dir = Directory(_tilesDirPath!);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

/// موفّر بلاطات يعطي الأولوية للنسخة المحفوظة محلياً، وإذا لم تكن محفوظة
/// يجلبها من الإنترنت مباشرة (بدون حفظها تلقائياً - الحفظ يتم فقط عبر
/// زر "تحميل الخريطة" صراحة، حتى لا تُستهلك بيانات المستخدم بدون علمه)
class OfflineFirstTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final z = coordinates.z.toInt();
    final x = coordinates.x.toInt();
    final y = coordinates.y.toInt();

    final cachedPath = OfflineMapService.cachedTilePath(z, x, y);
    if (cachedPath != null) {
      return FileImage(File(cachedPath));
    }

    final subdomains = options.subdomains;
    final subdomain =
        subdomains.isNotEmpty ? subdomains[(x + y) % subdomains.length] : '';
    final url = options.urlTemplate!
        .replaceAll('{s}', subdomain)
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y')
        .replaceAll('{r}', '');
    // إرسال User-Agent إلزامي حسب سياسة OpenStreetMap لتفادي حظر/تبطيء
    // الطلبات وظهور بلاطات ناقصة أو رمادية.
    return NetworkImage(
      url,
      headers: const {
        'User-Agent': 'DaleelZuwarAlHussein/1.0 (Flutter app; contact via app)',
      },
    );
  }
}
