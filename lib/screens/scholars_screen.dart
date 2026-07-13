import 'package:flutter/material.dart';
import '../data/scholars_data.dart';
import '../theme.dart';
import 'scholar_questions_screen.dart';

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
            child: ListTile(
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
          );
        },
      ),
    );
  }
}
