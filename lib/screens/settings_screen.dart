import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../theme.dart';
import '../data/ahlulbayt_dates_data.dart';
import '../models/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _notificationsEnabled = false;
  bool _prayerTimeReminder = false;
  bool _eventsReminder = false;
  bool _muharramReminder = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    final enabled = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;

    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  Future<void> _requestPermission() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      setState(() {
        _notificationsEnabled = granted ?? false;
      });

      if (_notificationsEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفعيل الإشعارات')),
        );
      }
    }
  }

  Future<void> _cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء جميع الإشعارات')),
      );
    }
  }

  /// ✅ إشعار فوري (للتذكير اليدوي)
  Future<void> _showInstantNotification(String title, String body) async {
    if (!_notificationsEnabled) {
      await _requestPermission();
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'instant_channel',
      'تذكير فوري',
      channelDescription: 'إشعارات فورية للمناسبات',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
    );
  }

  /// ✅ جدولة إشعار (للتذكير التلقائي)
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_notificationsEnabled) {
      await _requestPermission();
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'scheduled_channel',
      'تذكير مجدول',
      channelDescription: 'إشعارات مجدولة للمناسبات والصلوات',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// ✅ التذكير اليدوي بمناسبة معينة - عرض جميع المناسبات مع تصنيف
  void _showReminderDialog() {
    final allEvents = _getUpcomingEvents();

    // تصنيف المناسبات
    final births = allEvents.where((e) => e.kind == EventKind.birth).toList();
    final deaths = allEvents.where((e) => e.kind == EventKind.death).toList();

    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 3,
        child: AlertDialog(
          title: const Text('تذكير بمناسبة'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'الكل'),
                    Tab(text: 'ولادات'),
                    Tab(text: 'وفيات'),
                  ],
                  labelColor: AppColors.primaryGreen,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildEventsList(allEvents),
                      _buildEventsList(births),
                      _buildEventsList(deaths),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ بناء قائمة المناسبات
  Widget _buildEventsList(List<AhlulBaytEvent> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text('لا توجد مناسبات في هذا القسم'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          leading: Icon(
            event.kind == EventKind.birth ? Icons.brightness_5 : Icons.brightness_2,
            color: event.kind == EventKind.birth
                ? AppColors.primaryGreen
                : Colors.grey[700],
          ),
          title: Text(event.personName),
          subtitle: Text(
            '${event.kind == EventKind.birth ? 'ولادة' : 'وفاة/استشهاد'} - ${event.hijriDate}',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.notifications_active, color: AppColors.primaryGreen),
            onPressed: () {
              _showInstantNotification(
                'تذكير: ${event.personName}',
                '${event.kind == EventKind.birth ? 'ولادة' : 'وفاة/استشهاد'} ${event.personName} - ${event.hijriDate}',
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تم تعيين تذكير لـ ${event.personName}')),
              );
            },
          ),
        );
      },
    );
  }

  /// ✅ الحصول على جميع مناسبات أهل البيت (ولادات ووفيات)
  List<AhlulBaytEvent> _getUpcomingEvents() {
    return ahlulBaytEvents.toList();
  }

  // ==================== دوال المشاركة (مركزة في مكان واحد) ====================

  /// ✅ مشاركة عبر واتساب
  Future<void> _shareToWhatsApp() async {
    final text = Uri.encodeComponent(
      'حمل تطبيق دليل زوار الحسين - تطبيق ديني حسيني شامل\n'
      'يحتوي على: مواقيت الصلاة - أقوال وخطب - أسئلة شرعية - خريطة العراق - اتجاه القبلة\n'
      'حصراً على المذهب الشيعي الاثني عشري'
    );
    final url = Uri.parse('https://wa.me/?text=$text');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// ✅ مشاركة عبر تليجرام
  Future<void> _shareToTelegram() async {
    final text = Uri.encodeComponent(
      'حمل تطبيق دليل زوار الحسين - تطبيق ديني حسيني شامل\n'
      'يحتوي على: مواقيت الصلاة - أقوال وخطب - أسئلة شرعية - خريطة العراق - اتجاه القبلة\n'
      'حصراً على المذهب الشيعي الاثني عشري'
    );
    final url = Uri.parse('https://t.me/share/url?url=&text=$text');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// ✅ مشاركة عامة (نسخ النص)
  void _shareGeneral() {
    Clipboard.setData(const ClipboardData(
      text: 'حمل تطبيق دليل زوار الحسين - تطبيق ديني حسيني شامل\n'
            'يحتوي على: مواقيت الصلاة - أقوال وخطب - أسئلة شرعية - خريطة العراق - اتجاه القبلة\n'
            'حصراً على المذهب الشيعي الاثني عشري\n'
            'https://github.com/daleelzuwar/alhussein',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم نسخ نص المشاركة - الصقه في أي تطبيق'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// ✅ خيارات مشاركة التطبيق (BottomSheet)
  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'شارك التطبيق',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'انشر دليل زوار الحسين مع أصدقائك وعائلتك',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // نسخ الرابط
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primaryGreen),
              title: const Text('نسخ رابط التطبيق'),
              subtitle: const Text('انسخ الرابط والصقه في أي مكان'),
              onTap: () {
                Clipboard.setData(const ClipboardData(
                  text: 'حمل تطبيق دليل زوار الحسين - تطبيق ديني حسيني شامل\n'
                        'يحتوي على: مواقيت الصلاة - أقوال وخطب - أسئلة شرعية - خريطة العراق - اتجاه القبلة\n'
                        'حصراً على المذهب الشيعي الاثني عشري\n'
                        'https://github.com/daleelzuwar/alhussein',
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ تم نسخ نص المشاركة')),
                );
              },
            ),

            const Divider(),

            // مشاركة عبر واتساب
            ListTile(
              leading: const Icon(Icons.message, color: Color(0xFF25D366)),
              title: const Text('واتساب'),
              onTap: () {
                Navigator.pop(context);
                _shareToWhatsApp();
              },
            ),

            // مشاركة عبر تليجرام
            ListTile(
              leading: const Icon(Icons.send, color: Color(0xFF0088cc)),
              title: const Text('تليجرام'),
              onTap: () {
                Navigator.pop(context);
                _shareToTelegram();
              },
            ),

            // مشاركة عامة
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.primaryGreen),
              title: const Text('مشاركة عامة'),
              onTap: () {
                Navigator.pop(context);
                _shareGeneral();
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ============================================================================

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
          const _SettingTile(
            icon: Icons.directions_walk,
            title: 'طريق زائر الحسين',
            subtitle: 'حدد موقعك لمعرفة المسافة إلى كربلاء وفتح الخريطة',
          ),
          const _SettingTile(
            icon: Icons.menu_book,
            title: 'أسئلة شرعية',
            subtitle: 'اختر مرجعك الديني واطلع على الفتاوى',
          ),
          const _SettingTile(
            icon: Icons.format_quote,
            title: 'أقوال وخطب',
            subtitle: 'اقرأ أقوال الإمام الحسين وخطب السبايا',
          ),
          const _SettingTile(
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

          // ✅ تفعيل الإشعارات الرئيسي
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                _notificationsEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: AppColors.primaryGreen,
              ),
              title: const Text('تفعيل الإشعارات'),
              subtitle: Text(
                _notificationsEnabled
                    ? 'الإشعارات مفعلة'
                    : 'اضغط لتفعيل الإشعارات',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  if (value) {
                    _requestPermission();
                  } else {
                    setState(() {
                      _notificationsEnabled = false;
                      _prayerTimeReminder = false;
                      _eventsReminder = false;
                      _muharramReminder = false;
                    });
                    _cancelAllNotifications();
                  }
                },
                activeColor: AppColors.primaryGreen,
              ),
            ),
          ),

          // ✅ تذكير مواقيت الصلاة
          _NotificationTile(
            icon: Icons.access_time,
            title: 'تذكير مواقيت الصلاة',
            subtitle: 'إشعار عند دخول وقت الصلاة',
            enabled: _notificationsEnabled && _prayerTimeReminder,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _prayerTimeReminder = value)
                : null,
          ),

          // ✅ تذكير المناسبات (تلقائي)
          _NotificationTile(
            icon: Icons.calendar_today,
            title: 'تذكير المناسبات التلقائي',
            subtitle: 'ولادات ووفيات أهل البيت حسب التاريخ',
            enabled: _notificationsEnabled && _eventsReminder,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _eventsReminder = value)
                : null,
          ),

          // ✅ تذكير يدوي بمناسبة
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                Icons.add_alert,
                color: _notificationsEnabled ? AppColors.primaryGreen : Colors.grey,
              ),
              title: Text(
                'تذكير يدوي بمناسبة',
                style: TextStyle(
                  color: _notificationsEnabled ? Colors.black : Colors.grey,
                ),
              ),
              subtitle: Text(
                'اختر مناسبة لتذكيرك بها',
                style: TextStyle(
                  fontSize: 12,
                  color: _notificationsEnabled ? Colors.grey[600] : Colors.grey,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: _notificationsEnabled ? AppColors.primaryGreen : Colors.grey,
              ),
              onTap: _notificationsEnabled ? _showReminderDialog : null,
            ),
          ),

          // ✅ تذكير أيام محرم
          _NotificationTile(
            icon: Icons.mosque,
            title: 'تذكير أيام محرم',
            subtitle: 'إشعار قبل أيام عاشوراء',
            enabled: _notificationsEnabled && _muharramReminder,
            onChanged: _notificationsEnabled
                ? (value) => setState(() => _muharramReminder = value)
                : null,
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

          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: AppColors.primaryGreen),
                      SizedBox(width: 8),
                      Text(
                        'دليل زوار الحسين',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تطبيق ديني حسيني شامل يهدف إلى خدمة زوار الإمام الحسين عليه السلام وتوفير '
                    'المعلومات الشرعية والتاريخية والخدمية لهم.',
                    style: TextStyle(fontSize: 13, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'المميزات:\n'
                    '• مواقيت الصلاة حسب كراس السيد السيستاني دام ظله\n'
                    '• أقوال وخطب الإمام الحسين عليه السلام\n'
                    '• أسئلة شرعية وفتاوى\n'
                    '• تواريخ ولادات ووفيات أهل البيت عليهم السلام\n'
                    '• خريطة تفاعلية للأماكن المقدسة\n'
                    '• إشعارات وتذكير بالمناسبات',
                    style: TextStyle(fontSize: 12, height: 1.8),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Text('الإصدار: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('1.0.0'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Text('المطور: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('فريق دليل زوار الحسين'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // تواصل معنا
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(Icons.email, color: AppColors.primaryGreen),
              title: const Text('تواصل معنا'),
              subtitle: const Text('mhtraf6@gmail.com'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'mhtraf6@gmail.com',
                  queryParameters: {
                    'subject': 'اقتراح/ملاحظة - دليل زوار الحسين',
                  },
                );
                await launchUrl(emailUri);
              },
            ),
          ),

          // ✅ مشاركة التطبيق (مرة واحدة فقط)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: AppColors.lightGold.withOpacity(0.3),
            child: ListTile(
              leading: Icon(Icons.share, color: AppColors.primaryGreen),
              title: const Text('شارك التطبيق'),
              subtitle: const Text('انشر التطبيق مع الأصدقاء والعائلة'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: _showShareOptions,
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ بطاقة إعداد (بسيطة - بدون دوال مشاركة)
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

// ✅ زر مشاركة
class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ بطاقة إشعار (بسيطة - بدون دوال مشاركة)
class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: onChanged != null ? AppColors.primaryGreen : Colors.grey,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: onChanged != null ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: onChanged != null ? Colors.grey[600] : Colors.grey,
          ),
        ),
        trailing: Switch(
          value: enabled,
          onChanged: onChanged,
          activeColor: AppColors.primaryGreen,
        ),
      ),
    );
  }
}
