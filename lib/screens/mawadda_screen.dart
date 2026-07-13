import 'package:flutter/material.dart';
import '../data/hussein_quotes_data.dart';
import '../theme.dart';

class MawaddaScreen extends StatelessWidget {
  const MawaddaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مودة أهل البيت عليهم السلام')),
      body: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: mawaddaQuotes.length,
        itemBuilder: (context, index) {
          final q = mawaddaQuotes[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.favorite, color: AppColors.gold),
                  const SizedBox(height: 6),
                  Text(q.text,
                      style: const TextStyle(
                          fontSize: 16, height: 1.6, fontWeight: FontWeight.w600)),
                  const Divider(height: 20),
                  Text('المناسبة: ${q.occasion}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('المصدر: ${q.source}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
