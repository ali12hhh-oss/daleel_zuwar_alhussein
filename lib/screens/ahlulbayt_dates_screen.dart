import 'package:flutter/material.dart';
import '../data/ahlulbayt_dates_data.dart';
import '../models/models.dart';
import '../models/hijri_month.dart';
import '../services/hijri_calendar_service.dart';
import '../theme.dart';

/// خريطة أسماء الأشهر الهجرية (بأشهر تسمياتها المتداولة في المصادر الشيعية)
/// إلى رقم الشهر (1-12) المستخدم في جدول HijriCalendarService.
const Map<int, List<String>> _hijriMonthAliases = {
  1: ['محرم'],
  2: ['صفر'],
  3: ['ربيع الأول'],
  4: ['ربيع الآخر', 'ربيع الثاني'],
  5: ['جمادى الأولى', 'جمادى الاولى'],
  6: ['جمادى الآخرة', 'جمادى الثانية'],
  7: ['رجب'],
  8: ['شعبان'],
  9: ['رمضان'],
  10: ['شوال'],
  11: ['ذو القعدة', 'ذي القعدة'],
  12: ['ذو الحجة', 'ذي الحجة'],
};

/// يحول أي أرقام غربية داخل نص إلى أرقام عربية شرقية (١٢٣...)، ويترك
/// باقي النص كما هو. يُستخدم في كل مكان تُعرض فيه أرقام للمستخدم.
String _arabicDigits(Object value) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  var text = value.toString();
  for (var i = 0; i < western.length; i++) {
    text = text.replaceAll(western[i], eastern[i]);
  }
  return text;
}

/// يرجع التسمية القياسية (الأكثر تداولًا) لشهر هجري برقمه، أو null لو
/// الرقم غير معروف.
String? _canonicalMonthName(int monthNumber) {
  final aliases = _hijriMonthAliases[monthNumber];
  if (aliases == null || aliases.isEmpty) return null;
  return aliases.first;
}

class _ParsedHijriDate {
  final int day;
  final int monthNumber;
  const _ParsedHijriDate(this.day, this.monthNumber);
}

/// يحاول استخراج (يوم، رقم شهر) من نص رواية تاريخ حدث، مثل "3 شعبان" أو
/// "10 محرم (يوم عاشوراء)". يرجع null لو النص غير محدد بدقة (بدون يوم
/// رقمي واضح) بدل تخمين تاريخ غير مؤكد.
_ParsedHijriDate? _parseNarrationDate(String text) {
  final dayMatch = RegExp(r'\d+').firstMatch(text);
  if (dayMatch == null) return null;
  final day = int.tryParse(dayMatch.group(0)!);
  if (day == null || day < 1 || day > 30) return null;

  for (final entry in _hijriMonthAliases.entries) {
    for (final alias in entry.value) {
      if (text.contains(alias)) {
        return _ParsedHijriDate(day, entry.key);
      }
    }
  }
  return null;
}

/// يبني نص التاريخ الهجري بالترتيب العربي الصحيح دائمًا: اليوم ثم الشهر
/// ثم السنة (مثال: "١٧ ربيع الأول ١١٧ هـ")، بأرقام عربية شرقية، بغض
/// النظر عن الترتيب الذي كُتب فيه النص الأصلي في مصدر البيانات. يعتمد
/// على نفس منطق تحليل التاريخ المستخدم لحساب "المناسبة القادمة"، فلا
/// حاجة لتعديل ملف البيانات نفسه.
String formatHijriNarrationDate(Narration n) {
  final parsed = _parseNarrationDate(n.hijriDate);
  final buffer = StringBuffer();

  if (parsed != null) {
    buffer.write(_arabicDigits(parsed.day));
    final monthName = _canonicalMonthName(parsed.monthNumber);
    if (monthName != null) {
      buffer.write(' ');
      buffer.write(monthName);
    }
  } else {
    // تعذر تحليل اليوم والشهر بدقة؛ نعرض النص الأصلي بعد تحويل أرقامه فقط
    // بدل إخفائه بالكامل.
    buffer.write(_arabicDigits(n.hijriDate));
  }

  if (n.hijriYear != null) {
    buffer.write(' ');
    buffer.write(_arabicDigits(n.hijriYear!));
    buffer.write(' هـ');
  }

  return buffer.toString();
}

class NextOccasionResult {
  final AhlulBaytEvent event;
  final Narration narration;
  final DateTime date;
  const NextOccasionResult({
    required this.event,
    required this.narration,
    required this.date,
  });
}

/// يبحث بين كل روايات أهل البيت (المعتمدة/الأشهر فقط) عن أقرب مناسبة
/// قادمة أو جارية اليوم، بالاعتماد فقط على الأشهر الهجرية المُعلنة
/// فعلياً في جدول HijriCalendarService. أي مناسبة تقع في شهر لم
/// يُعلن بعد لن تُحسب حتى يُحدَّث الجدول.
Future<NextOccasionResult?> _computeNextOccasion() async {
  final months = await HijriCalendarService.getMonths();
  if (months.isEmpty) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  NextOccasionResult? best;

  for (final event in ahlulBaytEvents) {
    for (final narration in event.narrations) {
      if (!narration.isMostFamous) continue;
      final parsed = _parseNarrationDate(narration.hijriDate);
      if (parsed == null) continue;

      for (final month in months) {
        if (month.number != parsed.monthNumber) continue;
        if (parsed.day > month.days) continue;

        final occurrence = month.startDate.add(Duration(days: parsed.day - 1));
        if (occurrence.isBefore(today)) continue;

        if (best == null || occurrence.isBefore(best.date)) {
          best = NextOccasionResult(
            event: event,
            narration: narration,
            date: occurrence,
          );
        }
      }
    }
  }

  return best;
}

class AhlulBaytDatesScreen extends StatefulWidget {
  const AhlulBaytDatesScreen({super.key});

  @override
  State<AhlulBaytDatesScreen> createState() => _AhlulBaytDatesScreenState();
}

class _AhlulBaytDatesScreenState extends State<AhlulBaytDatesScreen> {
  bool _showBirths = true;
  bool _loadingNextOccasion = true;
  NextOccasionResult? _nextOccasion;

  final ScrollController _contentScrollController = ScrollController();

  // مفتاح واحد ثابت لكل حدث (بغض النظر عن كونه ولادة أو وفاة)، يُستخدم
  // للتمرير إلى بطاقته بالضبط عند الضغط على "المناسبة القادمة".
  late final Map<AhlulBaytEvent, GlobalKey> _eventKeys = {
    for (final e in ahlulBaytEvents) e: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _loadNextOccasion();
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNextOccasion() async {
    final result = await _computeNextOccasion();
    if (mounted) {
      setState(() {
        _nextOccasion = result;
        _loadingNextOccasion = false;
      });
    }
  }

  void _scrollToEvent(AhlulBaytEvent event) {
    final isBirth = event.kind == EventKind.birth;
    final filtered = ahlulBaytEvents
        .where((e) => e.kind == (isBirth ? EventKind.birth : EventKind.death))
        .toList();
    final index = filtered.indexOf(event);
    if (index < 0) return;

    setState(() => _showBirths = isBirth);

    // القفز التقريبي أولاً حتى يبني ListView.builder العنصر المطلوب
    // فعلياً (بسبب lazy loading)، ثم تصحيح دقيق بـ ensureVisible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_contentScrollController.hasClients) return;
      final target = (index * 260.0)
          .clamp(0.0, _contentScrollController.position.maxScrollExtent);
      _contentScrollController.jumpTo(target);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _eventKeys[event]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.05,
          );
        }
      });
    });
  }

  Widget _buildNextOccasionCard() {
    if (_loadingNextOccasion) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_nextOccasion == null) return const SizedBox.shrink();

    final r = _nextOccasion!;
    final isBirth = r.event.kind == EventKind.birth;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysLeft = r.date.difference(today).inDays;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _scrollToEvent(r.event),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    isBirth ? Icons.brightness_5 : Icons.brightness_2,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المناسبة القادمة',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.event.personName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${formatHijriNarrationDate(r.narration)}'
                        '  •  ${daysLeft <= 0 ? "اليوم" : "بعد ${_arabicDigits(daysLeft)} يوماً"}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_left, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _showBirths
        ? ahlulBaytEvents.where((e) => e.kind == EventKind.birth).toList()
        : ahlulBaytEvents.where((e) => e.kind == EventKind.death).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ولادات ووفيات أهل البيت'),
      ),
      body: Column(
        children: [
          // ✅ بطاقة المناسبة القادمة (تُحسب تلقائياً)
          _buildNextOccasionCard(),

          // ✅ أزرار التبديل
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showBirths = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showBirths ? AppColors.primaryGreen : Colors.grey[300],
                      foregroundColor: _showBirths ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('الولادات'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _showBirths = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showBirths ? AppColors.primaryGreen : Colors.grey[300],
                      foregroundColor: !_showBirths ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('الوفيات والاستشهادات'),
                  ),
                ),
              ],
            ),
          ),
          // ✅ قائمة الأحداث
          Expanded(
            child: _EventsList(
              events: events,
              controller: _contentScrollController,
              eventKeys: _eventKeys,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  final List<AhlulBaytEvent> events;
  final ScrollController controller;
  final Map<AhlulBaytEvent, GlobalKey> eventKeys;

  const _EventsList({
    required this.events,
    required this.controller,
    required this.eventKeys,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(14),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final e = events[index];
        final isBirth = e.kind == EventKind.birth;
        return Card(
          key: eventKeys[e],
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          isBirth ? AppColors.primaryGreen : Colors.grey[800],
                      child: Icon(
                        isBirth ? Icons.brightness_5 : Icons.brightness_2,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.personName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(e.description, style: const TextStyle(height: 1.4)),
                const SizedBox(height: 10),
                Text(
                  e.narrations.length > 1
                      ? 'الروايات الواردة في تاريخ الحدث (${_arabicDigits(e.narrations.length)}):'
                      : 'التاريخ:',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ...e.narrations.map((n) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: n.isMostFamous
                            ? AppColors.lightGold.withOpacity(0.35)
                            : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: n.isMostFamous
                            ? Border.all(color: AppColors.gold, width: 1)
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatHijriNarrationDate(n),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (n.isMostFamous)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.star,
                                      size: 14, color: AppColors.gold),
                                ),
                            ],
                          ),
                          if (n.note != null) ...[
                            const SizedBox(height: 2),
                            Text(n.note!,
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[700])),
                          ],
                          const SizedBox(height: 4),
                          Text('الرأي مسند إلى: ${n.attributedTo}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700])),
                        ],
                      ),
                    )),
                Text('المصدر العام: ${e.source}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
        );
      },
    );
  }
}
