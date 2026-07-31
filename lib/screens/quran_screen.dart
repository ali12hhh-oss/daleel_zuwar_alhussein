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
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.separated(
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
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text('$place · $verseCount آية', textDirection: TextDirection.rtl),
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

/// شاشة قراءة سورة كاملة، آية آية
class SurahReadingScreen extends StatelessWidget {
  final int surahNumber;
  const SurahReadingScreen({super.key, required this.surahNumber});

  /// يتحقق إذا كان الحرف من علامات التشكيل العربي (حركات، تنوين، شدة...)
  static bool _isDiacritic(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 0x064B && code <= 0x065F) ||
        code == 0x0670 ||
        (code >= 0x06D6 && code <= 0x06ED);
  }

  /// يحذف بداية النص إذا كانت تطابق نص البسملة، بتجاهل أي فروقات بالتشكيل
  /// بين النصين (لتفادي ظهور البسملة مكررة في الآية الأولى لبعض السور)
  static String _removeLeadingBasmala(String verseText) {
    final basmalaLetters = quran.basmala
        .split('')
        .where((c) => !_isDiacritic(c))
        .join();

    int verseIndex = 0;
    int basmalaIndex = 0;

    while (verseIndex < verseText.length && basmalaIndex < basmalaLetters.length) {
      final ch = verseText[verseIndex];
      if (_isDiacritic(ch)) {
        verseIndex++;
        continue;
      }
      if (ch == basmalaLetters[basmalaIndex]) {
        verseIndex++;
        basmalaIndex++;
      } else {
        return verseText; // مو بسملة مكررة، رجّع النص كما هو
      }
    }

    if (basmalaIndex == basmalaLetters.length) {
      return verseText.substring(verseIndex).trimLeft();
    }
    return verseText;
  }

  @override
  Widget build(BuildContext context) {
    final name = quran.getSurahNameArabic(surahNumber);
    final verseCount = quran.getVerseCount(surahNumber);
    // البسملة سطر مستقل غير مرقّم في بداية كل سورة، ما عدا سورة التوبة
    // (لا بسملة فيها حسب المصحف الشريف). لا نستثني الفاتحة: بحسب توثيق
    // مكتبة القرآن المستخدمة، البسملة منفصلة تمامًا عن نص الآيات لكل السور.
    final showBasmala = surahNumber != 9;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: verseCount + (showBasmala ? 1 : 0),
          itemBuilder: (context, index) {
            if (showBasmala && index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  quran.basmala,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              );
            }
            final verseNumber = showBasmala ? index : index + 1;
            final rawVerseText =
                quran.getVerse(surahNumber, verseNumber, verseEndSymbol: true);
            final verseText = (showBasmala && verseNumber == 1)
                ? _removeLeadingBasmala(rawVerseText)
                : rawVerseText;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                verseText,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
                style: const TextStyle(fontSize: 20, height: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
