import 'package:flutter/material.dart';
import '../widgets/section_card.dart';
import 'quran_screen.dart';
import 'book_viewer_screen.dart';
import 'mafatih_jinan_screen.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الكتب الدينية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
         SectionCard(
          title: 'القرآن الكريم',
          subtitle: 'نص القرآن الكريم كاملاً تصفح حسب السور',
          icon: Icons.menu_book,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuranScreen()),
          ),
        ),
      ],
    );
  }
}
