import '../models/models.dart';

/// قائمة أبرز مراجع ورموز الشيعة (للاختيار منها في قسم الأسئلة الشرعية).
/// جميع المراجع المذكورة هنا من المذهب الشيعي حصراً، بحسب طلب المستخدم.
/// ملاحظة: الروابط أدناه تم التحقق منها عبر البحث، لكن يجب مراجعتها
/// دورياً لأن مواقع المكاتب قد تتغيّر.
const List<Scholar> scholarsList = [
  Scholar(
    id: 'sistani',
    name: 'السيد علي السيستاني',
    title: 'المرجع الديني الأعلى',
    officialSite: 'https://www.sistani.org/arabic/',
    istiftaUrl: 'https://www.sistani.org/arabic/qa/',
    isLiving: true,
    hasRss: true,
    // ✅ تصحيح: الرابط القديم https://www.sistani.org/arabic/qa/feed/
    // كان يرجع 404 (غير موجود) - وهو سبب رسالة "فشل البحث". هذا هو
    // رابط RSS الصحيح والفعّال بالموقع الرسمي، تحقّقنا منه ويرجع محتوى
    // XML صالح فعلاً. ملاحظة: هذا الفيد يغطي كل تحديثات موقع السيستاني
    // (بيانات، أرشيف، استفتاءات) مو الاستفتاءات فقط.
    rssUrl: 'https://www.sistani.org/arabic/rss/',
  ),
  Scholar(
    id: 'sadr',
    name: 'السيد محمد محمد صادق الصدر',
    title: 'المرجع الديني (الشهيد الصدر الثاني)',
    // موقع هيئة تراث الشهيد السعيد السيد محمد الصدر (قدس سره) - الموقع
    // الرسمي الذي يحتوي قسم الاستفتاءات
    officialSite: 'https://alturaath.com/',
    istiftaUrl:
        'https://alturaath.com/questions/الشهيد%20السعيد%20آية%20الله%20العظمى%20السيد%20محمد%20الصدر?id=37d6e68b-e45b-45a2-866a-a2c1cbcba2b4',
    isLiving: false,
    hasRss: false,
  ),
  Scholar(
    id: 'khamenei',
    name: 'السيد علي الخامنئي',
    title: 'المرجع الديني وقائد الثورة الإسلامية',
    officialSite: 'https://arabic.khamenei.ir',
    istiftaUrl: 'https://arabic.khamenei.ir/others/toziholmasael',
    isLiving: true,
    hasRss: true,
    // ✅ رابط RSS الرسمي لقسم "الاستفتاءات" (مو كل الموقع) - مصدره
    // صفحة قوائم RSS الرسمية بالموقع (arabic.khamenei.ir/rss-list).
    // ملاحظة: الموقع يمنع أدوات الفحص الآلي (robots.txt)، لهذا ما قدرنا
    // نتحقق من محتواه مباشرة، بس هذا لا يمنع عادة طلبات تطبيق أندرويد
    // العادية (http package). جرب الزر وخبرني إذا طلعت نفس مشكلة
    // "فشل البحث" حتى نلاحقها.
    rssUrl: 'https://arabic.khamenei.ir/feed/service/11654',
  ),
  Scholar(
    id: 'shirazi',
    name: 'السيد صادق الشيرازي',
    title: 'المرجع الديني',
    officialSite: 'https://alshirazi.org/?langs=AR',
    istiftaUrl: 'https://alshirazi.org/estefta?langs=AR',
    isLiving: true,
    hasRss: false,
  ),
  Scholar(
    id: 'khoei',
    name: 'السيد أبو القاسم الخوئي',
    title: 'المرجع الديني الراحل',
    // الموقع الرسمي لمؤسسة الإمام الخوئي الخيرية
    officialSite: 'https://www.alkhoei.org/ar',
    istiftaUrl: 'https://www.alkhoei.org/ar',
    isLiving: false,
    hasRss: false,
  ),
];
