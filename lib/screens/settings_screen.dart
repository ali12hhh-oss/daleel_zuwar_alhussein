import 'package:flutter/material.dart';
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

  /// ✅ التذكير اليدوي بمناسبة معينة
  void _showReminderDialog() {
    final upcomingEvents = _getUpcomingEvents();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تذكير بمناسبة'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: upcomingEvents.length,
            itemBuilder: (context, index) {
              final event = upcomingEvents[index];
              return ListTile(
                leading: Icon(
                  event.kind == EventKind.birth ? Icons.brightness_5 : Icons.brightness_2,
                  color: event.kind == EventKind.birth
                      ? AppColors.primaryGreen
                      : Colors.grey[700],
                ),
                title: Text(event.personName),
                subtitle: Text(
                  event.kind == EventKind.birth ? 'ولادة' : 'وفاة/استشهاد',
                ),
                onTap: () {
                  _showInstantNotification(
                    'تذكير: ${event.personName}',
                    '${event.kind == EventKind.birth ? 'ولادة' : 'وفاة/استشهاد'} ${event.personName}',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم تعيين تذكير لـ ${event.personName}')),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// ✅ الحصول على المناسبات القادمة
  List<AhlulBaytEvent> _getUpcomingEvents() {
    return ahlulBaytEvents.take(10).toList();
  }

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
              // TODO: فتح البريد
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
