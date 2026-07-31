import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';

/// شاشة القرآن الكريم الكاملة (فهرس السور + بحث + عرض بشكل صفحات
/// المصحف الأصلية، مع تنسيق تلقائي حسب حجم شاشة الموبايل والبسملة
/// معروضة بشكل منفصل تمامًا عن نص الآيات).
///
/// نعتمد هنا على الـ widget الجاهز الرسمي من المكتبة بدل بناء الشاشة
/// يدويًا، لأن بعض دوال الـ API (مثل getSurahInfo) قد تختلف توقيعاتها
/// بين إصدارات المكتبة، بينما هذا الـ widget مضمون ومدعوم في كل
/// الإصدارات.
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: QuranLibraryScreen(
        parentContext: context,
        useDefaultAppBar: true,
        isDark: isDark,
      ),
    );
  }
}
