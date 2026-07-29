import 'package:flutter/material.dart';
import '../widgets/section_card.dart';
import 'quran_screen.dart';
import 'remote_book_viewer_screen.dart';

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
            subtitle: 'نص القرآن الكريم كاملاً، تصفح حسب السور',
            icon: Icons.menu_book,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuranScreen()),
            ),
          ),
          SectionCard(
            title: 'مفاتيح الجنان',
            subtitle: 'كتاب الأدعية والزيارات للشيخ عباس القمي (يُحمَّل عند أول فتح)',
            icon: Icons.auto_stories,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RemoteBookViewerScreen(
                  title: 'مفاتيح الجنان',
                  remoteUrl:
                      'https://raw.githubusercontent.com/ali12hhh-oss/daleel_zuwar_alhussein/main/assets/books/mafatih_al_jinan.pdf',
                  cacheFileName: 'mafatih_al_jinan.pdf',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
