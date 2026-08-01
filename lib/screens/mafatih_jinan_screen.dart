import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'mafatih_section_screen.dart';

/// نموذج قسم واحد (باب/فصل) من كتاب مفاتيح الجنان.
class MafatihSection {
  final String id;
  final String title;
  final int page;
  final String text;

  MafatihSection({
    required this.id,
    required this.title,
    required this.page,
    required this.text,
  });

  factory MafatihSection.fromJson(Map<String, dynamic> json) => MafatihSection(
        id: json['id'] as String,
        title: json['title'] as String,
        page: json['page'] as int,
        text: json['text'] as String,
      );
}

/// الشاشة الرئيسية لكتاب مفاتيح الجنان: تحمّل الكتاب من ملف JSON
/// المرفق داخل التطبيق (offline بالكامل، بدون إنترنت ولا PDF)،
/// وتعرض قائمة الأبواب/الفصول مع خانة بحث تبحث داخل نص الكتاب كامل.
class MafatihJinanScreen extends StatefulWidget {
  const MafatihJinanScreen({super.key});

  @override
  State<MafatihJinanScreen> createState() => _MafatihJinanScreenState();
}

class _MafatihJinanScreenState extends State<MafatihJinanScreen> {
  List<MafatihSection> _allSections = [];
  List<MafatihSection> _filtered = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final raw = await rootBundle.loadString('assets/books/mafatih_al_jinan.json');
      final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
      final List<dynamic> sectionsJson = data['sections'] as List<dynamic>;
      final sections = sectionsJson
          .map((e) => MafatihSection.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _allSections = sections;
          _filtered = sections;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر تحميل الكتاب. يرجى مراجعة المطوّر.';
          _loading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    final q = query.trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allSections;
      } else {
        _filtered = _allSections
            .where((s) => s.title.contains(q) || s.text.contains(q))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مفاتيح الجنان'),
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
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          textDirection: TextDirection.rtl,
                          decoration: InputDecoration(
                            hintText: 'ابحث داخل الكتاب... (مثال: دعاء الصباح)',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_filtered.isEmpty)
                        const Expanded(
                          child: Center(child: Text('لا توجد نتائج')),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final section = _filtered[index];
                              final query = _searchController.text.trim();
                              return ListTile(
                                title: Text(
                                  section.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: query.isNotEmpty && section.text.contains(query)
                                    ? Text(
                                        _snippetAround(section.text, query),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : Text('صفحة ${section.page}'),
                                trailing: const Icon(Icons.chevron_left),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MafatihSectionScreen(
                                      title: section.title,
                                      text: section.text,
                                      page: section.page,
                                      highlight: query.isEmpty ? null : query,
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

  /// يقتطع جزءاً قصيراً من النص حول أول مطابقة لعبارة البحث، لعرضه
  /// كمعاينة (preview) أسفل عنوان القسم في نتائج البحث.
  String _snippetAround(String text, String query) {
    final idx = text.indexOf(query);
    if (idx == -1) return text.substring(0, text.length.clamp(0, 80));
    final start = (idx - 30).clamp(0, text.length);
    final end = (idx + query.length + 30).clamp(0, text.length);
    final prefix = start > 0 ? '... ' : '';
    final suffix = end < text.length ? ' ...' : '';
    return '$prefix${text.substring(start, end)}$suffix';
  }
}
