import 'package:flutter/material.dart';
import '../data/battle_data.dart';
import '../theme.dart';

class BattleScreen extends StatelessWidget {
  const BattleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معركة الطف')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            color: AppColors.lightGold.withOpacity(0.4),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'أحداث معركة كربلاء في الأيام العشرة الأولى من محرم 61 هـ، '
                'والمعاناة التي واجهها الإمام الحسين وأهل بيته وأصحابه.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...battleTimeline.asMap().entries.map((entry) {
            final index = entry.key;
            final e = entry.value;
            return _BattleEventCard(
              index: index,
              day: e.day,
              title: e.title,
              description: e.description,
              source: e.source,
            );
          }),
        ],
      ),
    );
  }
}

// ✅ بطاقة الحدث مع التوسيع
class _BattleEventCard extends StatefulWidget {
  final int index;
  final int day;
  final String title;
  final String description;
  final String source;

  const _BattleEventCard({
    required this.index,
    required this.day,
    required this.title,
    required this.description,
    required this.source,
  });

  @override
  State<_BattleEventCard> createState() => _BattleEventCardState();
}

class _BattleEventCardState extends State<_BattleEventCard> {
  bool _isExpanded = false;

  // ✅ تقسيم النص إلى مقطعين (مقطع قصير + الباقي)
  String get _shortText {
    final words = widget.description.split(' ');
    if (words.length <= 20) return widget.description;
    return words.take(20).join(' ') + '...';
  }

  String get _fullText => widget.description;

  bool get _hasMoreText => widget.description.split(' ').length > 20;

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ رقم اليوم
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(23),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ العنوان
                    Text(
                      'اليوم ${widget.day} من محرم — ${widget.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ✅ النص (مقطع أو كامل)
                    Text(
                      _isExpanded ? _fullText : _shortText,
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
                    // ✅ زر "اقرأ المزيد" إذا كان النص طويلاً
                    if (_hasMoreText) ...[
                      const SizedBox(height: 8),
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
                    const SizedBox(height: 6),
                    // ✅ المصدر
                    Text(
                      'المصدر: ${widget.source}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
