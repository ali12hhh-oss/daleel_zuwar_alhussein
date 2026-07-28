class HijriMonthEntry {
  final String name;
  final int number;
  final int hijriYear;
  final DateTime startDate;
  final int days;

  const HijriMonthEntry({
    required this.name,
    required this.number,
    required this.hijriYear,
    required this.startDate,
    required this.days,
  });

  /// أول يوم من الشهر التالي (نهاية هذا الشهر، غير شاملة)
  DateTime get endDate => startDate.add(Duration(days: days));

  factory HijriMonthEntry.fromJson(Map<String, dynamic> json) {
    return HijriMonthEntry(
      name: json['name'] as String,
      number: json['number'] as int,
      hijriYear: json['hijriYear'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      days: json['days'] as int,
    );
  }
}

/// نتيجة البحث عن التاريخ الهجري المطابق لليوم الحالي
class HijriDateResult {
  final bool isKnown;
  final int? day;
  final String? monthName;
  final int? hijriYear;

  const HijriDateResult.known({
    required int day,
    required String monthName,
    required int hijriYear,
  })  : isKnown = true,
        day = day,
        monthName = monthName,
        hijriYear = hijriYear;

  const HijriDateResult.pending()
      : isKnown = false,
        day = null,
        monthName = null,
        hijriYear = null;

  /// نص جاهز للعرض، مثل: "١٥ محرم ١٤٤٧هـ"
  String get displayText {
    if (!isKnown) return '';
    return '$day $monthName ${hijriYear}هـ';
  }
}
