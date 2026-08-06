import 'package:flutter/material.dart';

class HusseinQuotesScreen extends StatelessWidget {
  const HusseinQuotesScreen({super.key});

  static const List<String> quotes = [
    'إن لم يكن لكم دين ولا تخافون المعاد فكونوا أحراراً في دنياكم',
    'الموت أولى من ركوب العار، والعار أولى من دخول النار',
    'إني لا أرى الموت إلا سعادة، والحياة مع الظالمين إلا برماً',
    'هيهات منا الذلة',
    // أضف بقية الأقوال هنا
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أقوال وخطب الإمام الحسين'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: quotes.length,
        separatorBuilder: (_, __) => const Divider(height: 24),
        itemBuilder: (context, index) {
          return Text(
            quotes[index],
            style: const TextStyle(fontSize: 18, height: 1.6),
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }
}
