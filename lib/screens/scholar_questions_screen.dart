import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/questions_data.dart';
import '../models/models.dart';
import '../theme.dart';

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
          Card(
            color: AppColors.lightGold.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الأجوبة حسب رأي: ${scholar.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (scholar.isLiving)
                    const Text(
                      'اضغط الزر أدناه للانتقال مباشرة إلى صفحة البحث في '
                      'المسائل الشرعية (الاستفتاءات) في الموقع الرسمي لمكتب '
                      'سماحته، للحصول على الفتاوى الدقيقة والمحدثة.',
                      style: TextStyle(fontSize: 13),
                    )
                  else
                    const Text(
                      'سماحته متوفى رحمه الله، ولا توجد استفتاءات جديدة '
                      'تصدر عن مكتبه؛ الرابط أدناه يقودك لمصادر عامة '
                      'للاطّلاع على تراثه الفقهي.',
                      style: TextStyle(fontSize: 13),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(scholar.istiftaUrl),
                          mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.search),
                      label: const Text('البحث في المسائل الشرعية (الاستفتاءات)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(scholar.officialSite),
                        mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('فتح الموقع الرسمي العام'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...questions.map((q) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.category,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Text('س: ${q.question}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('ج: ${q.answer}'),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
