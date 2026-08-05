import 'package:flutter/material.dart';
import '../theme.dart';
import 'duas_screen.dart';
import 'ziarat_screen.dart';

/// ✅ شاشة جامعة تحل محل الانتقال المباشر إلى شاشة الزيارات من الرئيسية.
/// تعرض زرّين: الأدعية (شاشة جديدة) والزيارات (الشاشة الحالية بلا تغيير).
class DuasZiaratScreen extends StatelessWidget {
  const DuasZiaratScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأدعية والزيارات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.lightGold.withOpacity(0.3),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.mosque, size: 48, color: AppColors.primaryGreen),
                  SizedBox(height: 12),
                  Text(
                    'الأدعية والزيارات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'اختر القسم الذي تريده',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _HubButton(
            title: 'الأدعية',
            subtitle: 'دعاء كميل، التوسل، الفرج، الاستخارة، وأدعية أخرى',
            icon: Icons.auto_stories,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DuasScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _HubButton(
            title: 'الزيارات',
            subtitle: 'عاشوراء، وارث، الأربعين، العباس، علي الأكبر، الأصحاب',
            icon: Icons.mosque,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ZiaratScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HubButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        splashColor: AppColors.gold.withOpacity(0.25),
        highlightColor: AppColors.gold.withOpacity(0.12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primaryGreen, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios, size: 16, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
