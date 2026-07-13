import 'package:flutter/material.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ تعريف بالتطبيق
          Card(
            color: AppColors.lightGold.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.mosque, size: 48, color: AppColors.primaryGreen),
                  const SizedBox(height: 12),
                  const Text(
                    'دليل زوار الحسين',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تطبيق ديني حسيني شامل يهدف إلى خدمة زوار الإمام الحسين عليه السلام '
                    'وتوفير المعلومات الشرعية والتاريخية والخدمية لهم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // ✅ كيفية الاستخدام
          const Text(
            'كيفية الاستخدام',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _SettingTile(
            icon: Icons.directions_walk,
            title: 'طريق زائر الحسين',
            subtitle: 'حدد موقعك لمعرفة المسافة إلى كربلاء وفتح الخريطة',
          ),
          _SettingTile(
            icon: Icons.menu_book,
            title: 'أسئلة شرعية',
            subtitle: 'اختر مرجعك الديني واطلع على الفتاوى',
          ),
          _SettingTile(
            icon: Icons.format_quote,
            title: 'أقوال وخطب',
            subtitle: 'اقرأ أقوال الإمام الحسين وخطب السبايا',
          ),
          _SettingTile(
            icon: Icons.calendar_month,
            title: 'التواريخ',
            subtitle: 'تعرف على مواليد ووفيات أهل البيت',
          ),
          const SizedBox(height: 16),
          
          // ✅ الإشعارات
          const Text(
            'الإشعارات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _NotificationTile(
            icon: Icons.access_time,
            title: 'مواقيت الصلاة',
            subtitle: 'تذكير بأوقات الصلاة',
          ),
          _NotificationTile(
            icon: Icons.calendar_today,
            title: 'الولادات والوفيات',
            subtitle: 'تذكير بمناسبات أهل البيت',
          ),
          _NotificationTile(
            icon: Icons.mosque,
            title: 'أيام محرم',
            subtitle: 'تذكير بأيام عاشوراء',
          ),
          const SizedBox(height: 16),
          
          // ✅ معلومات التطبيق
          const Text(
            'عن التطبيق',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.info, color: AppColors.primaryGreen),
            title: const Text('الإصدار'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: Icon(Icons.email, color: AppColors.primaryGreen),
            title: const Text('تواصل معنا'),
            subtitle: const Text('للاقتراحات والملاحظات'),
            onTap: () {
              // فتح البريد
            },
          ),
        ],
      ),
    );
  }
}

// ✅ بطاقة إعداد
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryGreen),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

// ✅ بطاقة إشعار
class _NotificationTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(widget.icon, color: AppColors.primaryGreen),
        title: Text(widget.title),
        subtitle: Text(widget.subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Switch(
          value: _enabled,
          onChanged: (value) {
            setState(() => _enabled = value);
            // ✅ طلب إذن الإشعارات
            if (value) {
              _requestNotificationPermission();
            }
          },
          activeColor: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    // سيتم تنفيذ طلب الإذن هنا
    // يحتاج مكتبة flutter_local_notifications
  }
}
