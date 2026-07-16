import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/questions_data.dart';
import '../models/models.dart';
import '../theme.dart';
import 'fatwas_screen.dart';

class ScholarQuestionsScreen extends StatelessWidget {
  final Scholar scholar;
  const ScholarQuestionsScreen({super.key, required this.scholar});

  @override
  Widget build(BuildContext context) {
    final questions =
        sampleQuestions.where((q) => q.scholarId == scholar.id).toList();

    return Scaffold(
      appBar: AppBar(title: Text(scholar.name)),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // بطاقة المعلومات
          Card(
            color: AppColors.lightGold.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scholar.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    scholar.title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (scholar.isLiving) ...[
                    const Text(
                      'للاستفتاء المباشر والحصول على الفتاوى الدقيقة:',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    // زر الاستفتاءات (RSS أو موقع)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (scholar.hasRss) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FatwasScreen(scholar: scholar),
                              ),
                            );
                          } else {
                            _launchUrl(context, scholar.istiftaUrl);
                          }
                        },
                        icon: Icon(scholar.hasRss ? Icons.rss_feed : Icons.open_in_new),
                        label: Text(scholar.hasRss 
                            ? 'استفتاءات ${scholar.name}' 
                            : 'البحث في الاستفتاءات'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scholar.hasRss ? Colors.orange : AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'سماحته متوفى رحمه الله، ولا توجد استفتاءات جديدة.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // زر الموقع الرسمي
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _launchUrl(context, scholar.officialSite),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('الموقع الرسمي'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // قسم الأسئلة الشائعة
          if (questions.isEmpty) ...[
            // عرض "قريباً" إذا لا توجد أسئلة
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'قريباً',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'سيتم إضافة أسئلة وأجوبة خاصة بالزوار من المواقع الرسمية للمراجع',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // عرض الأسئلة إذا موجودة
            const Text(
              'أسئلة شائعة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            ...questions.map((q) => _QuestionCard(question: q)),
          ],
        ],
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرابط غير متوفر')),
      );
      return;
    }
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الرابط')),
      );
    }
  }
}

// بطاقة السؤال والجواب
class _QuestionCard extends StatelessWidget {
  final ShariQuestion question;
  const _QuestionCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question.question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          question.category,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  question.answer,
                  style: const TextStyle(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
