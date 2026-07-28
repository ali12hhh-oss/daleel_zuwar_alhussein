import 'package:flutter/material.dart';
import '../models/hijri_month.dart';
import '../services/hijri_calendar_service.dart';

/// ودجت صغيرة تُضاف إلى actions في AppBar لعرض التاريخ الهجري.
/// في واجهة عربية (RTL) تظهر actions تلقائياً في أعلى يسار الشاشة.
class HijriDateBadge extends StatefulWidget {
  const HijriDateBadge({super.key});

  @override
  State<HijriDateBadge> createState() => _HijriDateBadgeState();
}

class _HijriDateBadgeState extends State<HijriDateBadge> {
  HijriDateResult? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await HijriCalendarService.getTodayHijriDate();
    if (mounted) {
      setState(() => _result = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    // أثناء التحميل، أو إذا لم يكن التاريخ مؤكداً ضمن الجدول، لا نعرض شيئاً
    // بدل عرض تاريخ خاطئ أو مُخمَّن.
    if (_result == null || !_result!.isKnown) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Text(
          _result!.displayText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
