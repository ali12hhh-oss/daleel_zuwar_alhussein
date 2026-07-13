import '../models/models.dart';

const List<Scholar> scholars = [
  Scholar(
    id: 'sistani',
    name: 'السيد علي السيستاني',
    title: 'آية الله العظمى',
    officialSite: 'https://www.sistani.org',
    istiftaUrl: 'https://www.sistani.org/arabic/qa/search/',
    isLiving: true,
  ),
  Scholar(
    id: 'khamenei',
    name: 'السيد علي الخامنئي',
    title: 'آية الله العظمى (شهيد)',
    officialSite: 'https://arabic.khamenei.ir',
    istiftaUrl: 'https://arabic.khamenei.ir/fatwa',
    isLiving: true,
  ),
  Scholar(
    id: 'sadr',
    name: 'السيد محمد الصدر',
    title: 'آية الله العظمى (شهيد)',
    officialSite: 'https://jawabna.com',
    istiftaUrl: 'https://jawabna.com',
    isLiving: false,
  ),
  Scholar(
    id: 'shirazi',
    name: 'السيد صادق الحسيني الشيرازي',
    title: 'آية الله العظمى',
    officialSite: 'https://shirazi.ir',
    istiftaUrl: 'https://shirazi.ir/fa/qa/',
    isLiving: true,
  ),
  Scholar(
    id: 'khoei',
    name: 'السيد أبو القاسم الخوئي',
    title: 'آية الله العظمى (رحمه الله)',
    officialSite: 'https://alkhoei.net',
    istiftaUrl: '',
    isLiving: false,
  ),
  Scholar(
    id: 'haeri',
    name: 'السيد كمال الحيدري',
    title: 'آية الله العظمى',
    officialSite: 'https://alhaydari.com',
    istiftaUrl: 'https://alhaydari.com/ar/category/estefta/',
    isLiving: true,
  ),
  Scholar(
    id: 'najafi',
    name: 'الشيخ بشير حسين النجفي',
    title: 'آية الله العظمى',
    officialSite: 'https://alnajafi.org',
    istiftaUrl: '',
    isLiving: true,
  ),
];

const List<String> questionCategories = [
  'العبادات (الصلاة، الصوم، الحج)',
  'الطهارة والنجاسة',
  'الزيارة ومناسك كربلاء',
  'المعاملات المالية',
  'الأسرة والمواريث',
  'مسائل متفرقة',
];

// ✅ قسم الأسئلة الشرعية - قريباً
// سيتم إضافة أسئلة وأجوبة خاصة بالزوار من المواقع الرسمية للمراجع
// حسب المعتقد الشيعي الإثني عشري
const List<ShariQuestion> sampleQuestions = [];
