import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hijri_month.dart';

class HijriCalendarService {
  // الرابط الخام لملف التقويم الهجري داخل مجلد lib/data/ في المستودع
  // (نفس المجلد الذي يحوي ahlulbayt_dates_data.dart وغيره)
  static const String _remoteUrl =
      'https://raw.githubusercontent.com/ali12hhh-oss/daleel_zuwar_alhussein/main/lib/data/hijri_calendar.json';

  static const String _cacheKey = 'hijri_calendar_json_cache';

  /// يجلب الجدول من الإنترنت، ويخزّنه محلياً كنسخة احتياطية.
  /// إذا فشل الاتصال، يستخدم آخر نسخة مخزّنة على الجهاز.
  static Future<List<HijriMonthEntry>> _fetchMonths() async {
    String? jsonString;

    try {
      final response = await http
          .get(Uri.parse(_remoteUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        jsonString = response.body;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonString);
      }
    } catch (_) {
      // لا يوجد إنترنت أو فشل الطلب - سنعتمد على النسخة المخزّنة محلياً
    }

    if (jsonString == null) {
      final prefs = await SharedPreferences.getInstance();
      jsonString = prefs.getString(_cacheKey);
    }

    if (jsonString == null) return [];

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final rawList = data['hijriMonths'] as List;
      final months = rawList
          .map((e) => HijriMonthEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      months.sort((a, b) => a.startDate.compareTo(b.startDate));
      return months;
    } catch (_) {
      return [];
    }
  }

  /// يبحث عن الشهر واليوم الهجري المطابق لتاريخ اليوم ضمن الجدول.
  /// إذا كان اليوم خارج كل الأشهر المُدخلة (بعد آخر إعلان أو قبل أول شهر
  /// مُدخل)، يعيد نتيجة "pending" بدل تخمين تاريخ غير مؤكد.
  static Future<HijriDateResult> getTodayHijriDate() async {
    final months = await _fetchMonths();
    if (months.isEmpty) return const HijriDateResult.pending();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final month in months) {
      final start = DateTime(
        month.startDate.year,
        month.startDate.month,
        month.startDate.day,
      );
      final end = start.add(Duration(days: month.days));

      if (!today.isBefore(start) && today.isBefore(end)) {
        final dayNumber = today.difference(start).inDays + 1;
        return HijriDateResult.known(
          day: dayNumber,
          monthName: month.name,
          hijriYear: month.hijriYear,
        );
      }
    }

    return const HijriDateResult.pending();
  }

  /// ✅ دالة عامة جديدة تُعيد جدول الأشهر الهجرية كاملاً كما هو منشور
  /// حالياً (نفس مصدر البيانات المستخدم في getTodayHijriDate أعلاه).
  /// تُستخدم في مطابقة تواريخ مناسبات أهل البيت (ahlulbayt_dates_data)
  /// بتواريخها الميلادية الفعلية لجدولة إشعارات تلقائية بها.
  /// ملاحظة مهمة: الجدول يغطي فقط الأشهر المعلنة حتى الآن (اعتماداً على
  /// رؤية الهلال الفعلية وليس حساباً فلكياً مسبقاً)، لذلك أي مناسبة
  /// تقع في شهر لم يُعلن بعد (عادة أشهر بعيدة في المستقبل) لن تُطابَق
  /// ولن تُجدوَل لها إشعارات حتى يُحدَّث الجدول لاحقاً.
  static Future<List<HijriMonthEntry>> getMonths() => _fetchMonths();
}
