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

/// شاشة قراءة سورة كاملة، نصاً متصلاً كتدفق واحد (وليس آية بكل سطر)
class SurahReadingScreen extends StatelessWidget {
  final int surahNumber;
  const SurahReadingScreen({super.key, required this.surahNumber});

  static const int _tawbah = 9;

  /// كل السور تُعرض لها البسملة كسطر مستقل أعلى الصفحة ما عدا سورة التوبة.
  /// البسملة ليست آية في أي سورة (ولا حتى الفاتحة)، ولا تُرقَّم ولا تُحسب
  /// ضمن نص الآيات إطلاقاً.
  bool get _showBasmala => surahNumber != _tawbah;

  /// يتحقق إذا كان الحرف من علامات التشكيل العربي (حركات، تنوين، شدة...)
  static bool _isDiacritic(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 0x064B && code <= 0x065F) ||
        code == 0x0670 ||
        (code >= 0x06D6 && code <= 0x06ED);
  }

  /// يحذف بداية النص إذا كانت تطابق نص البسملة (كلياً أو جزئياً في البداية)،
  /// بتجاهل أي فروقات بالتشكيل بين النصين. هذا يعمل بشكل صحيح بغضّ النظر عن
  /// كون البسملة مدمجة مع نص الآية الأولى (أغلب السور)، أو كون الآية بأكملها
  /// هي البسملة نفسها (حالة سورة الفاتحة) — وفي هذه الحالة الأخيرة يرجع نصاً
  /// فارغاً، ما يسمح لنا بتجاهل هذه "الآية" تماماً وعدم ترقيمها.
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
        return verseText; // مو بسملة، رجّع النص كما هو
      }
    }

    if (basmalaIndex == basmalaLetters.length) {
      return verseText.substring(verseIndex).trimLeft();
    }
    return verseText;
  }

  /// يبني نص السورة كاملاً كتيار واحد متصل (بدون فصل كل آية بسطر مستقل)،
  /// مع إضافة رمز نهاية الآية ورقمها الصحيح بعد كل آية، ومع حذف البسملة
  /// من بداية النص إن وُجدت، وعدم احتسابها كآية إطلاقاً.
  String _buildSurahBody() {
    final rawVerseCount = quran.getVerseCount(surahNumber);
    final buffer = StringBuffer();
    int displayNumber = 0;

    for (int v = 1; v <= rawVerseCount; v++) {
      var text = quran.getVerse(surahNumber, v, verseEndSymbol: false);

      if (_showBasmala && v == 1) {
        text = _removeLeadingBasmala(text).trim();
        if (text.isEmpty) {
          // هذه الآية في بيانات المكتبة هي البسملة نفسها فقط (حالة الفاتحة)
          // فلا تُعرض ولا تُحسب كآية مستقلة
          continue;
        }
      }

      displayNumber++;
      buffer
        ..write(text)
        ..write(' ')
        ..write(quran.getVerseEndSymbol(displayNumber, arabicNumeral: true))
        ..write(' ');
    }

    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final name = quran.getSurahNameArabic(surahNumber);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_showBasmala)
                Padding(
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
                ),
              Text(
                _buildSurahBody(),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
                style: const TextStyle(fontSize: 20, height: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
