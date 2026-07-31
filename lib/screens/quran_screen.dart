import 'package:flutter/material.dart';
import 'package:quran_library/quran_library.dart';
import '../theme.dart';

/// شاشة قائمة سور القرآن الكريم (114 سورة)
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
          itemCount: 114,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final surahNumber = index + 1;
            final surah = QuranLibrary().getSurahInfo(surahNumber);

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                child: Text(
                  '$surahNumber',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              title: Text(
                surah.name,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                '${surah.place} · ${surah.numberOfAyahs} آية',
                textDirection: TextDirection.rtl,
              ),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SurahReadingScreen(surahNumber: surahNumber),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// شاشة قراءة سورة كاملة، بشكل صفحات المصحف الأصلية.
/// النص يُنسَّق تلقائيًا حسب حجم شاشة الموبايل (وليس آية بكل سطر)،
/// والبسملة معروضة بشكل منفصل تمامًا عن نص الآيات دون أي تكرار.
class SurahReadingScreen extends StatelessWidget {
  final int surahNumber;
  const SurahReadingScreen({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    final surah = QuranLibrary().getSurahInfo(surahNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(surah.name)),
      body: SurahDisplayScreen(
        surahNumber: surahNumber,
        isDark: isDark,
      ),
    );
  }
}
