import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// تخزين محلي دائم نسبيًا لسجل قضاء الصلاة.
///
/// كل البيانات تحفظ على الجهاز، ويمكن تصديرها إلى ملف JSON واستعادتها لاحقًا.
class QadaPrayerService {
  QadaPrayerService._();

  static const String _key = 'qada_prayer_data_v1';

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return defaultData();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final data = Map<String, dynamic>.from(decoded);
        final merged = defaultData()..addAll(data);
        return merged;
      }
    } catch (_) {
      // في حال تلف البيانات نعيد الحالة الافتراضية دون تعطيل التطبيق.
    }
    return defaultData();
  }

  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  static Map<String, dynamic> defaultData() {
    return <String, dynamic>{
      'version': 1,
      'personName': '',
      'days': 30,
      'startDate': DateTime.now().toIso8601String(),
      'targets': <String, dynamic>{
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      },
      // المفتاح: dayIndex-prayerKey  مثل  0-fajr
      'checks': <String, dynamic>{},
      'planDaily': 5,
      'planEnabled': false,
      'reminderEnabled': false,
      'reminderHour': 21,
      'reminderMinute': 0,
      // السجلات الإضافية اختيارية ولا تدخل ضمن إجمالي الصلوات اليومية.
      'showQasr': false,
      'showAyat': false,
      'extraTotals': <String, dynamic>{
        'qasrDhuhr': 0,
        'qasrAsr': 0,
        'qasrIsha': 0,
        'ayat': 0,
      },
      'extraCompleted': <String, dynamic>{
        'qasrDhuhr': 0,
        'qasrAsr': 0,
        'qasrIsha': 0,
        'ayat': 0,
      },
      'extraEvents': <dynamic>[],
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// نسخة احتياطية كاملة: تحفظ كل بيانات القسم كما هي،
  /// بما فيها الصلوات الخمس، خطة القضاء، السجل، التذكيرات،
  /// صلاة القصر (الظهر والعصر والعشاء)، وصلاة الآيات.
  static Future<String> exportCompleteBackup() async {
    final data = await load();
    return jsonEncode(<String, dynamic>{
      'format': 'daleel_zuwar_qada_complete',
      'version': 3,
      'exportedAt': DateTime.now().toIso8601String(),
      'data': data,
    });
  }

  /// استعادة النسخة الاحتياطية الكاملة.
  static Future<bool> importCompleteBackup(String content) async {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map) return false;
      final rawData = decoded['data'];
      if (rawData is! Map) return false;

      final data = Map<String, dynamic>.from(rawData);

      final totals = data['extraTotals'];
      data['extraTotals'] = totals is Map
          ? Map<String, dynamic>.from(totals)
          : <String, dynamic>{
              'qasrDhuhr': 0,
              'qasrAsr': 0,
              'qasrIsha': 0,
              'ayat': 0,
            };
      final currentTotals = Map<String, dynamic>.from(data['extraTotals']);
      currentTotals.putIfAbsent('qasrIsha', () => 0);
      data['extraTotals'] = currentTotals;

      final completed = data['extraCompleted'];
      data['extraCompleted'] = completed is Map
          ? Map<String, dynamic>.from(completed)
          : <String, dynamic>{
              'qasrDhuhr': 0,
              'qasrAsr': 0,
              'qasrIsha': 0,
              'ayat': 0,
            };
      final currentCompleted = Map<String, dynamic>.from(data['extraCompleted']);
      currentCompleted.putIfAbsent('qasrIsha', () => 0);
      data['extraCompleted'] = currentCompleted;

      final events = data['extraEvents'];
      data['extraEvents'] =
          events is List ? List<dynamic>.from(events) : <dynamic>[];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(data));
      return true;
    } catch (_) {
      return false;
    }
  }
}
