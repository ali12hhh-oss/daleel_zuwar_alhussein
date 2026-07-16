import 'package:flutter/material.dart';
import '../data/scholars_data.dart';
import '../theme.dart';
import 'scholar_questions_screen.dart';
import 'fatwas_screen.dart';

class ScholarsScreen extends StatelessWidget {
  const ScholarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختر المرجع الديني')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: scholarsList.length,
        itemBuilder: (context, index) {
          final scholar = scholarsList[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryGreen,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(scholar.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(scholar.title),
                  trailing: const Icon(Icons.arrow_back_ios, size: 14),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScholarQuestionsScreen(scholar: scholar),
                    ),
                  ),
                ),
                // ✅ أزرار إضافية
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      // زر الأسئلة الشرعية
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ScholarQuestionsScreen(scholar: scholar),
                              ),
                            );
                          },
                          icon: const Icon(Icons.question_answer, size: 18),
                          label: const Text('الأسئلة الشرعية'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ✅ زر الاستفتاءات (RSS) - يظهر فقط إذا كان hasRss = true
                      if (scholar.hasRss) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FatwasScreen(scholar: scholar),
                                ),
                              );
                            },
                            icon: const Icon(Icons.rss_feed, size: 18),
                            label: const Text('الاستفتاءات'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
