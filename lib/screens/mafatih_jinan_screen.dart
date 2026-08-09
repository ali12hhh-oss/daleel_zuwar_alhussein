import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// شاشة مفاتيح الجنان النصية الكاملة (بدون PDF). المحتوى محمّل من
/// ملف JSON مبني من نص الكتاب الكامل وفهرسه الأصلي (تم تقسيم النص
/// آلياً حسب عناوين الفهرس الحقيقية). تدعم فهرساً جانبياً، بحثاً
/// بالعناوين والنصوص معاً، وتكبير/تصغير حجم الخط (يُحفظ التفضيل).
class MafatihJinanScreen extends StatefulWidget {
  const MafatihJinanScreen({super.key});

  @override
  State<MafatihJinanScreen> createState() => _MafatihJinanScreenState();
}

class MafatihEntry {
  final int id;
  final String title;
  final String content;
  final String titleNormalized;
  final String contentNormalized;

  MafatihEntry({
    required this.id,
    required this.title,
    required this.content,
  })  : titleNormalized = _normalizeArabic(title),
        contentNormalized = _normalizeArabic(content);

  factory MafatihEntry.fromJson(Map<String, dynamic> j) => MafatihEntry(
        id: j['id'] as int,
        title: j['title'] as String,
        content: j['content'] as String,
      );
}

/// يحذف التشكيل (الحركات) ويوحّد أشكال الألف/الياء/التاء المربوطة، حتى
/// يقدر المستخدم يبحث بكلمة بسيطة بدون تشكيل (مثل "دعاء") وتنطابق مع
/// النص المشكّل بالكتاب (مثل "دُعَاءُ").
String _normalizeArabic(String s) {
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    // نطاق الحركات والتنوين والسكون والمدّة والتطويل
    if ((rune >= 0x064B && rune <= 0x0652) || rune == 0x0670 || rune == 0x0640) {
      continue;
    }
    var ch = String.fromCharCode(rune);
    if (ch == 'أ' || ch == 'إ' || ch == 'آ') {
      ch = 'ا';
    } else if (ch == 'ى') {
      ch = 'ي';
    } else if (ch == 'ة') {
      ch = 'ه';
    }
    buffer.write(ch);
  }
  return buffer.toString();
}

List<MafatihEntry> _parseEntries(String jsonStr) {
  final list = json.decode(jsonStr) as List;
  return list
      .map((e) => MafatihEntry.fromJson(e as Map<String, dynamic>))
      .toList();
}

class _MafatihJinanScreenState extends State<MafatihJinanScreen> {
  static const String _assetPath = 'assets/books/mafatih_aljanan.json';
  static const double _minFont = 14;
  static const double _maxFont = 30;
  static const double _defaultFont = 19;

  List<MafatihEntry> _entries = [];
  bool _loading = true;
  String? _error;

  int _selectedIndex = 0;
  bool _showIndex = false;
  String _indexQuery = '';
  double _fontSize = _defaultFont;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFontSize();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble('mafatih_font_size');
    if (saved != null && mounted) {
      setState(() => _fontSize = saved);
    }
  }

  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('mafatih_font_size', _fontSize);
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(_minFont, _maxFont);
    });
    _saveFontSize();
  }

  Future<void> _loadData() async {
    try {
      final jsonStr = await DefaultAssetBundle.of(context).loadString(_assetPath);
      final entries = await compute(_parseEntries, jsonStr);
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر تحميل محتوى الكتاب.\nيرجى مراجعة المطوّر.';
          _loading = false;
        });
      }
    }
  }

  List<MapEntry<int, MafatihEntry>> get _filteredIndex {
    final indexed = _entries.asMap().entries.toList();
    if (_indexQuery.trim().isEmpty) return indexed;
    final q = _normalizeArabic(_indexQuery.trim());
    return indexed
        .where((e) =>
            e.value.titleNormalized.contains(q) ||
            e.value.contentNormalized.contains(q))
        .toList();
  }

  void _selectEntry(int index) {
    setState(() {
      _selectedIndex = index;
      _showIndex = false;
    });
    if (_contentScrollController.hasClients) {
      _contentScrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _entries.isNotEmpty ? _entries[_selectedIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مفاتيح الجنان'),
        actions: [
          if (!_loading && _error == null) ...[
            IconButton(
              tooltip: 'تصغير الخط',
              icon: const Icon(Icons.text_decrease),
              onPressed: () => _changeFontSize(-1),
            ),
            IconButton(
              tooltip: 'تكبير الخط',
              icon: const Icon(Icons.text_increase),
              onPressed: () => _changeFontSize(1),
            ),
            InkWell(
              onTap: () => setState(() => _showIndex = !_showIndex),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_showIndex ? Icons.close : Icons.search, size: 22),
                    const SizedBox(width: 4),
                    const Text('الفهرست', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : Stack(
                  children: [
                    _buildContent(current),
                    if (_showIndex) ...[
                      GestureDetector(
                        onTap: () => setState(() => _showIndex = false),
                        child: Container(color: Colors.black.withOpacity(0.4)),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildIndexPanel(),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildContent(MafatihEntry? current) {
    if (current == null) {
      return const Center(child: Text('لا يوجد محتوى'));
    }
    return SingleChildScrollView(
      controller: _contentScrollController,
      padding: const EdgeInsets.all(20),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              current.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _fontSize + 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            SelectableText(
              current.content.isEmpty ? '(لا يوجد نص محدد لهذا العنوان بعد)' : current.content,
              style: TextStyle(fontSize: _fontSize, height: 1.9),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_selectedIndex > 0)
                  TextButton.icon(
                    onPressed: () => _selectEntry(_selectedIndex - 1),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('السابق'),
                  )
                else
                  const SizedBox(),
                if (_selectedIndex < _entries.length - 1)
                  TextButton.icon(
                    onPressed: () => _selectEntry(_selectedIndex + 1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('التالي'),
                    iconAlignment: IconAlignment.end,
                  )
                else
                  const SizedBox(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// يبني عنوان الفهرس مع تمييز كلمة البحث بلون بارز (برتقالي غامق)
  /// إذا كانت موجودة ضمن العنوان.
  Widget _highlightedTitle(String title, String query, {required bool bold}) {
    final baseStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: Colors.black87,
    );
    final q = query.trim();
    if (q.isEmpty) {
      return Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: baseStyle);
    }
    final spans = <TextSpan>[];
    int start = 0;
    final lowerTitle = title;
    final lowerQuery = q;
    while (true) {
      final idx = lowerTitle.indexOf(lowerQuery, start);
      if (idx < 0) {
        spans.add(TextSpan(text: title.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: title.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: title.substring(idx, idx + lowerQuery.length),
        style: const TextStyle(
          color: Color(0xFFE65100),
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xFFFFE0B2),
        ),
      ));
      start = idx + lowerQuery.length;
    }
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

  Widget _buildIndexPanel() {
    final filtered = _filteredIndex;
    return Container(
      width: 300,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            color: Theme.of(context).primaryColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.search, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'الفهرست',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _indexQuery = v),
                  autofocus: false,
                  cursorColor: Theme.of(context).primaryColor,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black54),
                    hintText: 'بحث بالعنوان أو النص',
                    hintStyle: const TextStyle(fontSize: 12.5, color: Colors.black45),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _indexQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _indexQuery = '');
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('لا توجد نتائج', style: TextStyle(fontSize: 13)),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final entry = filtered[i];
                      final isSelected = entry.key == _selectedIndex;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        title: _highlightedTitle(
                          entry.value.title,
                          _indexQuery,
                          bold: isSelected,
                        ),
                        onTap: () => _selectEntry(entry.key),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
