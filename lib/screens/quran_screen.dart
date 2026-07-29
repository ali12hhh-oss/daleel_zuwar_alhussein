import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import '../theme.dart';

/// شاشة قائمة سور القرآن الكريم (114 سورة)
class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: ListView.separated(
        itemCount: 114,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final surahNumber = index + 1;
          final name = quran.getSurahNameArabic(surahNumber);
          final verseCount = quran.getVerseCount(surahNumber);
          final place = quran.getPlaceOfRevelation(surahNumber);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              child: Text('$surahNumber', style: const TextStyle(fontSize: 13)),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text('$place · $verseCount آية'),
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
    );
  }
}

/// شاشة قراءة سورة كاملة، آية آية
class SurahReadingScreen extends StatelessWidget {
  final int surahNumber;
  const SurahReadingScreen({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    final name = quran.getSurahNameArabic(surahNumber);
    final verseCount = quran.getVerseCount(surahNumber);
    // البسملة تُعرض منفصلة لكل السور ما عدا الفاتحة (تحتويها ضمن آياتها
    // أصلاً) وسورة التوبة (لا بسملة فيها حسب المصحف الشريف)
    final showBasmalaSeparately = surahNumber != 1 && surahNumber != 9;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: verseCount + (showBasmalaSeparately ? 1 : 0),
        itemBuilder: (context, index) {
          if (showBasmalaSeparately && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                quran.basmala,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGreen,
                ),
              ),
            );
          }
          final verseNumber = showBasmalaSeparately ? index : index + 1;
          final verseText =
              quran.getVerse(surahNumber, verseNumber, verseEndSymbol: true);
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              verseText,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 20, height: 2),
            ),
          );
        },
      ),
    );
  }
}
