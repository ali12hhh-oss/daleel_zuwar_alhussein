import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import '../theme.dart';

/// شاشة قائمة سور القرآن الكريم (114 سورة) مع خاصية البحث
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // نبني قائمة كل السور مرة واحدة فقط (بدل استدعاء المكتبة داخل كل itemBuilder)
  late final List<_SurahInfo> _allSurahs = List.generate(114, (index) {
    final surahNumber = index + 1;
    return _SurahInfo(
      number: surahNumber,
      name: quran.getSurahNameArabic(surahNumber),
      verseCount: quran.getVerseCount(surahNumber),
      place: quran.getPlaceOfRevelation(surahNumber),
    );
  });

  List<_SurahInfo> get _filteredSurahs {
    if (_query.trim().isEmpty) return _allSurahs;

    final numericQuery = int.tryParse(_query.trim());
    if (numericQuery != null) {
      return _allSurahs.where((s) => s.number == numericQuery).toList();
    }

    return _allSurahs.where((s) => s.name.contains(_query.trim())).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredSurahs;

    return Scaffold(
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'ابحث عن سورة بالاسم أو الرقم',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const Center(
                      child: Text(
                        'لا توجد نتائج',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final surah = results[index];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            child: Text(
                              '${surah.number}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          title: Text(
                            surah.name,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${surah.place} · ${surah.verseCount} آية',
                            textDirection: TextDirection.rtl,
                          ),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SurahReadingScreen(surahNumber: surah.number),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahInfo {
  final int number;
  final String name;
  final int verseCount;
  final String place;

  const _SurahInfo({
    required this.number,
    required this.name,
    required this.verseCount,
    required this.place,
  });
}

/// شاشة قراءة سورة كاملة، نصاً متصلاً كتدفق واحد (وليس آية بكل سطر)
/// مع إمكانية تكبير/تصغير حجم الخط.
class SurahReadingScreen extends StatefulWidget {
  final int surahNumber;
  const SurahReadingScreen({super.key, required this.surahNumber});

  @override
  State<SurahReadingScreen> createState() => _SurahReadingScreenState();
}

class _SurahReadingScreenState extends State<SurahReadingScreen> {
  static const int _tawbah = 9;

  // حدود وخطوة تكبير/تصغير الخط
  static const double _minFontSize = 16;
  static const double _maxFontSize = 36;
  static const double _fontStep = 2;

  double _fontSize = 20; // القيمة الافتراضية (كانت ثابتة سابقاً)

  int get surahNumber => widget.surahNumber;

  bool get _canIncrease => _fontSize < _maxFontSize;
  bool get _canDecrease => _fontSize > _minFontSize;

  void _increaseFontSize() {
    if (!_canIncrease) return;
    setState(() {
      _fontSize = (_fontSize + _fontStep).clamp(_minFontSize, _maxFontSize);
    });
  }

  void _decreaseFontSize() {
    if (!_canDecrease) return;
    setState(() {
      _fontSize = (_fontSize - _fontStep).clamp(_minFontSize, _maxFontSize);
    });
  }

  /// كل السور تُعرض لها البسملة كسطر مستقل أعلى الصفحة ما عدا سورة التوبة.
  /// البسملة ليست آية في أي سورة (ولا حتى الفاتحة)، ولا تُرقَّم ولا تُحسب
  /// ضمن نص الآيات إطلاقاً.
  bool get _showBasmala => surahNumber != _tawbah;

  /// عدد كلمات البسملة الثابت. نعتمد عليه بدل مقارنة الحروف لأن أشكال
  /// الحروف (ألف الوصل، رموز مدمجة للفظ الجلالة، فروقات تشكيل...) تختلف
  /// أحياناً بين نص البسملة المستقل ونص الآية المدمج بنفس مصدر البيانات،
  /// فتفشل أي مقارنة حرف-بحرف. عدّ الكلمات مضمون لأنه لا يعتمد على تطابق
  /// الحروف إطلاقاً، فقط على وجود مسافات فاصلة بين الكلمات (وهذا ثابت دوماً
  /// بالنص العربي).
  static int get _basmalaWordCount =>
      quran.basmala.trim().split(RegExp(r'\s+')).length;

  /// يحذف أول N كلمة من بداية النص، حيث N = عدد كلمات البسملة، بشرط أن
  /// يكون عدد كلمات الآية كافياً (أكبر من أو يساوي N). إذا كانت الآية
  /// بأكملها هي البسملة (حالة الفاتحة)، يرجع نصاً فارغاً.
  static String _removeLeadingBasmala(String verseText) {
    final words = verseText.trim().split(RegExp(r'\s+'));
    final n = _basmalaWordCount;

    if (words.length < n) return verseText; // احتياط: نص أقصر من البسملة

    final remaining = words.sublist(n);
    return remaining.join(' ');
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
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'تصغير الخط',
            icon: const Icon(Icons.text_decrease),
            onPressed: _canDecrease ? _decreaseFontSize : null,
          ),
          IconButton(
            tooltip: 'تكبير الخط',
            icon: const Icon(Icons.text_increase),
            onPressed: _canIncrease ? _increaseFontSize : null,
          ),
        ],
      ),
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
                    style: TextStyle(
                      fontSize: _fontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              Text(
                _buildSurahBody(),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: _fontSize, height: 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
