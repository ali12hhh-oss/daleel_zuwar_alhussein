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
  const MafatihEntry({required this.id, required this.title, required this.content});

  factory MafatihEntry.fromJson(Map<String, dynamic> j) => MafatihEntry(
        id: j['id'] as int,
        title: j['title'] as String,
        content: j['content'] as String,
      );
}

List<MafatihEntry> _parseEntries(String jsonStr) {
  final list = json.decode(jsonStr) as List;
  return list
      .map((e) => MafatihEntry.fromJson(e as Map<String, dynamic>))
      .toList();
}

class _MafatihJinanScreenState extends State<MafatihJinanScreen> {
  static const String _assetPath = 'assets/data/mafatih_aljanan.json';
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
    final q = _indexQuery.trim();
    return indexed
        .where((e) => e.value.title.contains(q) || e.value.content.contains(q))
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
            IconButton(
              tooltip: _showIndex ? 'إخفاء الفهرس' : 'إظهار الفهرس',
              icon: Icon(_showIndex ? Icons.menu_open : Icons.menu_book),
              onPressed: () => setState(() => _showIndex = !_showIndex),
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
                const Text(
                  'الفهرس',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _indexQuery = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'بحث بالعنوان أو النص',
                    hintStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _indexQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
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
                        title: Text(
                          entry.value.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
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
