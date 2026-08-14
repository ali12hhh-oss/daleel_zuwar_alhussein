import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// تخزين محلي دائم لسجل قضاء الصلاة.
///
/// كل البيانات تُحفظ على الجهاز عبر SharedPreferences، ويمكن تصديرها إلى
/// ملف JSON واستعادتها لاحقًا من خلال الأزرار الموجودة في شاشة قضاء الصلاة
/// (حفظ نسخة احتياطية / استعادة نسخة احتياطية).
class QadaPrayerService {
  QadaPrayerService._();

  static const String _key = 'qada_prayer_data_v1';

  /// يقرأ البيانات المحفوظة، ويدمجها دائمًا مع [defaultData] لضمان وجود
  /// كل المفاتيح المطلوبة حتى لو كانت نسخة قديمة من البيانات ناقصة.
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
    final now = DateTime.now();
    return <String, dynamic>{
      'version': 1,
      'personName': '',
      'days': 30,
      'startDate': DateTime(now.year, now.month, now.day).toIso8601String(),
      'targets': <String, dynamic>{
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      },
      // المفتاح: dayIndex-prayerKey  مثل  0-fajr
      'checks': <String, dynamic>{},
      // العدد المسجل يدويًا عبر زر "تم قضاء صلاة" لكل نوع صلاة
      'manualCompleted': <String, dynamic>{
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      },
      // سجل تفصيلي بالتاريخ لكل عملية قضاء، سواء من الزر المباشر أو من الجدول
      'events': <dynamic>[],
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
}
