import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/sabaya_data.dart';
import '../theme.dart';

class SabayaScreen extends StatefulWidget {
  const SabayaScreen({super.key});

  @override
  State<SabayaScreen> createState() => _SabayaScreenState();
}

class _SabayaScreenState extends State<SabayaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  // تصنيف الخطب حسب الشخصية
  final List<String> _categories = [
    'الكل',
    'السيدة زينب',
    'الإمام زين العابدين',
    'أم كلثوم',
    'فاطمة الصغرى',
    'السيدة رقية',
    'وصف المسيرة',
  ];

  // تحديد التصنيف لكل خطبة
  String _getCategory(int index) {
    final source = sabayaSermons[index].source.toLowerCase();
    if (source.contains('زينب')) return 'السيدة زينب';
    if (source.contains('زين العابدين') || source.contains('علي بن الحسين')) return 'الإمام زين العابدين';
    if (source.contains('أم كلثوم')) return 'أم كلثوم';
    if (source.contains('فاطمة الصغرى')) return 'فاطمة الصغرى';
    if (source.contains('رقية')) return 'السيدة رقية';
    if (source.contains('مسيرة') || source.contains('وصف')) return 'وصف المسيرة';
    return 'السيدة زينب';
  }

  // فلترة الخطب
  List<int> get _filteredIndices {
    List<int> indices = List.generate(sabayaSermons.length, (i) => i);

    // فلترة حسب التصنيف
    if (_selectedCategory != 'الكل') {
      indices = indices.where((i) => _getCategory(i) == _selectedCategory).toList();
    }

    // فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      indices = indices.where((i) {
        final q = sabayaSermons[i];
        return q.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               q.occasion.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               q.source.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return indices;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredIndices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('خطب السبايا'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // حقل البحث
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'ابحث في الخطب...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              // تصفية حسب الشخصية
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                        selectedColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            color: AppColors.lightGold.withOpacity(0.4),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'خطب أهل بيت الإمام الحسين عليه السلام السبايا، من كربلاء '
                'إلى الكوفة فالشام وحتى رجوعهم إلى المدينة المنورة.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // عدد النتائج
          if (_searchQuery.isNotEmpty || _selectedCategory != 'الكل')
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'عدد النتائج: ${filtered.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),

          // قائمة الخطب المفلترة
          if (filtered.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'لا توجد نتائج',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ...filtered.map((index) {
              final q = sabayaSermons[index];
              return _SermonCard(
                index: index,
                text: q.text,
                occasion: q.occasion,
                source: q.source,
                category: _getCategory(index),
              );
            }),
        ],
      ),
    );
  }
}

// بطاقة الخطبة مع التوسيع والنسخ
class _SermonCard extends StatefulWidget {
  final int index;
  final String text;
  final String occasion;
  final String source;
  final String category;

  const _SermonCard({
    required this.index,
    required this.text,
    required this.occasion,
    required this.source,
    required this.category,
  });

  @override
  State<_SermonCard> createState() => _SermonCardState();
}

class _SermonCardState extends State<_SermonCard> {
  bool _isExpanded = false;

  String get _shortText {
    final words = widget.text.split(' ');
    if (words.length <= 30) return widget.text;
    return words.take(30).join(' ') + '...';
  }

  bool get _hasMoreText => widget.text.split(' ').length > 30;

  // نسخ النص
  Future<void> _copyText() async {
    final fullText = widget.text + '\n\n' +
        'المناسبة: ' + widget.occasion + '\n' +
        'المصدر: ' + widget.source + '\n\n' +
        'من تطبيق دليل زوار الحسين';

    await Clipboard.setData(ClipboardData(text: fullText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ الخطبة'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // مشاركة النص
  void _shareText() {
    _copyText();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الخطبة -- الصقها في اي تطبيق'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (_hasMoreText) {
            setState(() => _isExpanded = !_isExpanded);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // رقم الخطبة + التصنيف
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryGreen,
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.occasion,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // تصنيف الشخصية
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightGold.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.category,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // النص
              Icon(Icons.format_quote, color: AppColors.gold, size: 20),
              const SizedBox(height: 8),
              Text(
                _isExpanded ? widget.text : _shortText,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // زر التوسيع
              if (_hasMoreText) ...[
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primaryGreen,
                    ),
                    label: Text(
                      _isExpanded ? 'اخفاء' : 'اقرأ المزيد',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const Divider(height: 20),

              // المصدر + ازرار النسخ والمشاركة
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'المصدر: ${widget.source}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  // زر النسخ
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    color: AppColors.primaryGreen,
                    tooltip: 'نسخ الخطبة',
                    onPressed: _copyText,
                  ),
                  // زر المشاركة
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    color: AppColors.primaryGreen,
                    tooltip: 'مشاركة الخطبة',
                    onPressed: _shareText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
