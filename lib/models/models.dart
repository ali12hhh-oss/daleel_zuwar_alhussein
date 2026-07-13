/// عالم دين (مرجع تقليد)
class Scholar {
  final String id;
  final String name;
  final String title;
  final String officialSite; // الموقع الرسمي العام
  final String istiftaUrl; // رابط صفحة الاستفتاءات/البحث الشرعي مباشرة
  final bool isLiving; // هل المرجع حي (توجد استفتاءات جديدة) أم لا

  const Scholar({
    required this.id,
    required this.name,
    required this.title,
    required this.officialSite,
    required this.istiftaUrl,
    this.isLiving = true,
  });
}

/// سؤال شرعي وجوابه حسب مرجع معيّن
class ShariQuestion {
  final String scholarId;
  final String category; // العبادات، المعاملات، ...
  final String question;
  final String answer;
  final bool isSample; // للإشارة إلى أن المحتوى نموذجي ويجب التحقق منه رسمياً

  const ShariQuestion({
    required this.scholarId,
    required this.category,
    required this.question,
    required this.answer,
    this.isSample = true,
  });
}

/// قول أو خطبة للإمام الحسين عليه السلام، أو حديث في مودة أهل البيت
class Quote {
  final String text;
  final String source; // المصدر (الكتاب/المرجع)
  final String occasion; // المناسبة أو السياق
  final bool isSample;

  const Quote({
    required this.text,
    required this.source,
    required this.occasion,
    this.isSample = true,
  });
}

/// حدث من أحداث معركة الطف ضمن الأيام العشرة
class BattleEvent {
  final int day; // من 1 إلى 10 (محرم)
  final String title;
  final String description;
  final String source;

  const BattleEvent({
    required this.day,
    required this.title,
    required this.description,
    required this.source,
  });
}

/// نوع المناسبة: ولادة أو وفاة/استشهاد
enum EventKind { birth, death }

/// رواية واحدة لتاريخ حدث (يوم/شهر، وسنة إن وردت)، مع الجهة/المصدر
/// الذي نُسبت إليه هذه الرواية تحديداً.
class Narration {
  final String hijriDate; // اليوم والشهر الهجري لهذه الرواية
  final String? hijriYear;
  final String attributedTo; // المصدر/الكتاب الذي نقل هذه الرواية تحديداً
  final bool isMostFamous; // هل هذه هي الرواية الأشهر/المعتمدة في أغلب التقاويم المعاصرة
  final String? note; // ✅ إضافة note

  const Narration({
    required this.hijriDate,
    this.hijriYear,
    required this.attributedTo,
    this.isMostFamous = false,
    this.note, // ✅ إضافة note
  });
}

/// حدث ولادة أو وفاة/استشهاد لأحد أهل البيت عليهم السلام حسب مصادر الشيعة.
/// قد يحمل الحدث الواحد أكثر من رواية للتاريخ، لاختلاف المصادر الشيعية
/// نفسها في تحديد اليوم بدقة.
class AhlulBaytEvent {
  final String personName; // اسم المعصوم/الشخصية
  final EventKind kind;
  final List<Narration> narrations; // رواية واحدة أو أكثر لتاريخ نفس الحدث
  final String description; // كيفية الوفاة/الاستشهاد أو مناسبة الولادة
  final String source; // مصادر عامة إضافية

  const AhlulBaytEvent({
    required this.personName,
    required this.kind,
    required this.narrations,
    required this.description,
    required this.source,
  });
}

/// مدينة عراقية مع إحداثياتها ومسافتها التقريبية إلى كربلاء
class IraqiCity {
  final String name;
  final double lat;
  final double lng;
  final double approxDistanceKm; // مسافة تقريبية بالطريق (وليست خط مستقيم)

  const IraqiCity({
    required this.name,
    required this.lat,
    required this.lng,
    required this.approxDistanceKm,
  });
}
