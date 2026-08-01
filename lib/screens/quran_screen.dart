import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import '../theme.dart';

/// شاشة قائمة سور القرآن الكريم (114 سورة) مع خانة بحث بالاسم.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allSurahNumbers = List.generate(114, (i) => i + 1);
    final filtered = _query.trim().isEmpty
        ? allSurahNumbers
        : allSurahNumbers.where((n) {
            final name = quran.getSurahNameArabic(n);
            return name.contains(_query.trim());
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('القرآن الكريم')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن سورة...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'بحث في الآيات',
                    icon: const Icon(Icons.manage_search),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AyahSearchScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('لا توجد نتائج'))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final surahNumber = filtered[index];
                        final name = quran.getSurahNameArabic(surahNumber);
                        final verseCount = quran.getVerseCount(surahNumber);
                        final place =
                            quran.getPlaceOfRevelation(surahNumber);

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
                            name,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            '$place · $verseCount آية',
                            textDirection: TextDirection.rtl,
                          ),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SurahReadingScreen(surahNumber: surahNumber),
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

/// شاشة قراءة سورة كاملة، نصاً متصلاً كتدفق واحد (وليس آية بكل سطر).
///
/// ملاحظة: حزمة quran (من الإصدار 1.1.0 فأعلى) تحذف البسملة تلقائياً من
/// نص الآية الأولى في كل سورة (ما عدا التوبة)، وتوفر quran.basmala كنص
/// منفصل للعرض. لذلك لا حاجة إطلاقاً لأي معالجة يدوية لحذف البسملة من
/// نص الآيات - المكتبة نفسها تضمن عدم التكرار.
class SurahReadingScreen extends StatelessWidget {
  final int surahNumber;
  final int? highlightAyah;
  const SurahReadingScreen({
    super.key,
    required this.surahNumber,
    this.highlightAyah,
  });

  static const int _tawbah = 9;

  bool get _showBasmala => surahNumber != _tawbah;

  /// يبني نص السورة كاملاً كتيار واحد متصل، مع رمز نهاية الآية ورقمها
  /// بعد كل آية. لا حاجة لأي معالجة للبسملة هنا لأن المكتبة تتكفل بذلك.
  String _buildSurahBody() {
    final verseCount = quran.getVerseCount(surahNumber);
    final buffer = StringBuffer();

    for (int v = 1; v <= verseCount; v++) {
      final text = quran.getVerse(surahNumber, v, verseEndSymbol: false);
      buffer
        ..write(text)
        ..write(' ')
        ..write(quran.getVerseEndSymbol(v, arabicNumeral: true))
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

/// شاشة بحث في نص جميع آيات القرآن الكريم (بالكلمات).
class AyahSearchScreen extends StatefulWidget {
  const AyahSearchScreen({super.key});

  @override
  State<AyahSearchScreen> createState() => _AyahSearchScreenState();
}

class _AyahSearchScreenState extends State<AyahSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  void _search(String value) {
    final word = value.trim();
    if (word.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final searchResult = quran.searchWords([word]);
    final resultData = searchResult['result'];
    final List<Map<String, dynamic>> parsed = [];
    if (resultData is List) {
      for (final item in resultData) {
        if (item is Map) {
          parsed.add(Map<String, dynamic>.from(item));
        }
      }
    }
    setState(() => _results = parsed);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بحث في الآيات')),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                textDirection: TextDirection.rtl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'اكتب كلمة من الآية...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _search,
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('اكتب كلمة للبحث عنها بالآيات'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        final surahNumber = item['surah'] as int;
                        final verseNumber = item['verse'] as int;
                        final text = quran.getVerse(
                          surahNumber,
                          verseNumber,
                          verseEndSymbol: true,
                        );
                        final surahName =
                            quran.getSurahNameArabic(surahNumber);

                        return ListTile(
                          title: Text(
                            text,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          ),
                          subtitle: Text(
                            '$surahName - آية $verseNumber',
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SurahReadingScreen(
                                surahNumber: surahNumber,
                                highlightAyah: verseNumber,
                              ),
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
