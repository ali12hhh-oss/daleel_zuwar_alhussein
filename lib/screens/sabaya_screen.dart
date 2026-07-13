import 'package:flutter/material.dart';
import '../data/sabaya_data.dart';
import '../theme.dart';

class SabayaScreen extends StatelessWidget {
  const SabayaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطب السبايا')),
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
          ...sabayaSermons.map((q) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote, color: AppColors.gold),
                      const SizedBox(height: 6),
                      Text(q.text,
                          style: const TextStyle(
                              fontSize: 15,
                              height: 1.7,
                              fontWeight: FontWeight.w600)),
                      const Divider(height: 20),
                      Text('المناسبة: ${q.occasion}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('المصدر: ${q.source}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
