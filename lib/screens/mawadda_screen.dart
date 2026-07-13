import 'package:flutter/material.dart';
import '../data/hussein_quotes_data.dart';
import '../theme.dart';

class MawaddaScreen extends StatelessWidget {
  const MawaddaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مودة أهل البيت عليهم السلام')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            color: AppColors.lightGold.withOpacity(0.4),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'أحاديث نبوية مشهورة في مودة أهل البيت عليهم السلام، '
                'منقولة من المصادر الشيعية المعتمدة.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...mawaddaQuotes.asMap().entries.map((entry) {
            final index = entry.key;
            final q = entry.value;
            return _HadithCard(
              index: index,
              text: q.text,
              occasion: q.occasion,
              source: q.source,
            );
          }),
        ],
      ),
    );
  }
}

// ✅ بطاقة الحديث مع التوسيع
class _HadithCard extends StatefulWidget {
  final int index;
  final String text;
  final String occasion;
  final String source;

  const _HadithCard({
    required this.index,
    required this.text,
    required this.occasion,
    required this.source,
  });

  @override
  State<_HadithCard> createState() => _HadithCardState();
}

class _HadithCardState extends State<_HadithCard> {
  bool _isExpanded = false;

  // ✅ تقسيم النص إلى مقطعين (مقطع قصير + الباقي)
  String get _shortText {
    final words = widget.text.split(' ');
    if (words.length <= 25) return widget.text;
    return words.take(25).join(' ') + '...';
  }

  String get _fullText => widget.text;

  bool get _hasMoreText => widget.text.split(' ').length > 25;

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
              // ✅ رقم الحديث
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
                ],
              ),
              const SizedBox(height: 12),
              // ✅ النص (مقطع أو كامل)
              Icon(Icons.favorite, color: AppColors.gold, size: 20),
              const SizedBox(height: 8),
              Text(
                _isExpanded ? _fullText : _shortText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // ✅ زر "اقرأ المزيد" إذا كان النص طويلاً
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
                      _isExpanded ? 'إخفاء' : 'اقرأ المزيد',
                      style: const TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              const Divider(height: 20),
              // ✅ المصدر
              Text(
                'المصدر: ${widget.source}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
