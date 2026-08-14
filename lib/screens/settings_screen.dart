import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme.dart';
import '../data/ahlulbayt_dates_data.dart';
import '../models/models.dart';
import '../models/hijri_month.dart';
import '../services/hijri_calendar_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ✅ مشغّل صوت مخصص فقط لمعاينة صوت الأذان داخل شاشة الإعدادات (منفصل
  // تماماً عن آلية جدولة إشعارات الأذان الفعلية في prayer_times_screen)
  final AudioPlayer _previewPlayer = AudioPlayer();

  bool _notificationsEnabled = false;
  bool _prayerTimeReminder = false;
  bool _eventsReminder = false;
  bool _muharramReminder = false;
  bool _loading = true;

  // ✅ إعدادات صوت الأذان الجديدة: نمط التنبيه (صوت / اهتزاز / صامت)
  // ومستوى صوت المعاينة داخل التطبيق. تُقرأ من قِبل شاشة مواقيت الصلاة
  // عند جدولة إشعارات الأذان الفعلية.
  String _adhanSoundMode = 'sound'; // 'sound' | 'vibrate' | 'silent'
  double _adhanVolume = 1.0;
  // ✅ اختيار مقطع الأذان: 'adhan1' أو 'adhan2' - يجب أن يكون لكل منهما
  // نسخة في android/app/src/main/res/raw/ (للإشعار الفعلي) ونسخة في
  // assets/sounds/ (لزر المعاينة داخل التطبيق)، بنفس الاسم بالضبط.
  String _adhanSoundFile = 'adhan1'; // 'adhan1' | 'adhan2'

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// ✅ نُشغّل التهيئة بالتسلسل وليس بالتوازي، لسببين اثنين.
  /// أولاً: تفادي تصادم نوافذ صلاحيات النظام إن استُدعيت شاشات أخرى معاً.
  /// ثانياً وهو الأهم هنا: _loadSettings() تتحقق من قيمة _notificationsEnabled
  ///    لتقرر هل تُعيد جدولة تذكير المناسبات تلقائياً. إن استدعيناها قبل
  ///    اكتمال _initNotifications() فعلياً، ستقرأ القيمة الافتراضية
  ///    (false) الخاطئة حتى لو كانت الإشعارات مفعّلة فعلاً على الجهاز.
  Future<void> _initApp() async {
    await _initNotifications();
    await _loadSettings();
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prayerTimeReminder = prefs.getBool('prayerTimeReminder') ?? false;
      _eventsReminder = prefs.getBool('eventsReminder') ?? false;
      _muharramReminder = prefs.getBool('muharramReminder') ?? false;
      _adhanSoundMode = prefs.getString('adhanSoundMode') ?? 'sound';
      _adhanVolume = prefs.getDouble('adhanVolume') ?? 1.0;
      _adhanSoundFile = prefs.getString('adhanSoundFile') ?? 'adhan1';
      _loading = false;
    });

    // ✅ إذا كان تذكير المناسبات مفعّلاً مسبقاً، نعيد جدولته من جديد في
    // كل مرة تُفتح فيها شاشة الإعدادات (وليس فقط عند أول تفعيل). السبب:
    // جدول hijri_calendar.json يُحدَّث دورياً عن بُعد (شهر جديد يُعلن)،
    // فإعادة الجدولة هنا تضمن مطابقة أي مناسبات جديدة أصبحت الآن ضمن
    // نطاق الجدول المنشور، دون انتظار المستخدم لإعادة تفعيل المفتاح يدوياً.
    if (_notificationsEnabled && _eventsReminder) {
      // لا ننتظر (await) هذه العملية عمداً حتى لا تُبطئ فتح الشاشة،
      // فهي عملية شبكة قد تستغرق وقتاً وليست حرجة للعرض الفوري.
      _scheduleEventsReminders();
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// ✅ حفظ نمط تنبيه الأذان (صوت/اهتزاز/صامت). شاشة مواقيت الصلاة تقرأ
  /// هذه القيمة قبل كل عملية جدولة، وتبني معرّف قناة إشعار مختلف لكل
  /// نمط (channel id يتضمن اسم النمط) لأن قنوات أندرويد لا يمكن تعديل
  /// إعداداتها (كالصوت) بعد إنشائها لأول مرة.
  Future<void> _saveAdhanSoundMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adhanSoundMode', mode);
    setState(() => _adhanSoundMode = mode);
  }

  Future<void> _saveAdhanVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('adhanVolume', volume);
    setState(() => _adhanVolume = volume);
  }

  /// ✅ حفظ اختيار مقطع الأذان (adhan1 أو adhan2).
  Future<void> _saveAdhanSoundFile(String file) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adhanSoundFile', file);
    setState(() => _adhanSoundFile = file);
  }

  /// ✅ تشغيل معاينة صوت الأذان المختار (adhan1 أو adhan2) بمستوى الصوت
  /// المحدد، داخل التطبيق فقط. ملاحظة مهمة: هذا يشغّل نسخة الصوت من
  /// assets/sounds/<fileName>.mp3 (نسخة منفصلة عن ملفات
  /// android/app/src/main/res/raw/<fileName>.mp3 المستخدمة فعلياً في
  /// إشعارات الأذان المجدولة عند إغلاق التطبيق) - لأن مشغّلات الصوت داخل
  /// التطبيق (audioplayers) لا يمكنها الوصول لموارد أندرويد الأصلية
  /// (raw) مباشرة، فقط لملفات assets الخاصة بفلاتر.
  ///
  /// ✅ إصلاح: كان الكود يستدعي setVolume() ثم play() بشكل منفصل، وهذا
  /// لا يُطبَّق بشكل موثوق في audioplayers لأن تحميل مصدر صوت جديد قد
  /// يُعيد ضبط مستوى الصوت لقيمته الافتراضية (1.0) بعد استدعاء setVolume
  /// وقبل بدء التشغيل الفعلي. الحل الصحيح هو تمرير مستوى الصوت مباشرة
  /// كمعامل volume إلى play() نفسها، وهذا مضمون التطبيق دائماً.
  Future<void> _previewAdhanSound(String fileName) async {
    try {
      await _previewPlayer.stop();
      await _previewPlayer.play(
        AssetSource('sounds/$fileName.mp3'),
        volume: _adhanVolume,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذّر تشغيل المعاينة. تأكد من وجود assets/sounds/$fileName.mp3',
            ),
          ),
        );
      }
    }
  }

  /// ✅ يُستدعى أثناء سحب شريط الصوت مباشرة (وليس فقط عند تركه)، حتى
  /// يسمع المستخدم تأثير رفع/خفض الصوت فوراً إن كان الصوت قيد التشغيل
  /// فعلاً، بدل الحاجة لإيقاف التشغيل وإعادة الضغط على "تجربة" في كل مرة.
  Future<void> _applyLiveVolumePreview(double volume) async {
    try {
      await _previewPlayer.setVolume(volume);
    } catch (_) {
      // لا شيء يستدعي التصرف هنا؛ لو لم يكن هناك تشغيل جارٍ فلا تأثير له أصلاً
    }
  }

  Future<void> _initNotifications() async {
    // ✅ إصلاح: لم يكن هذا الملف يستدعي tz.setLocalLocation() إطلاقاً
    // سابقاً (فقط initializeTimeZones())، وهذا كان سيرمي استثناءً فوراً
    // (LateInitializationError) بمجرد استخدام أي جدولة حقيقية عبر
    // zonedSchedule التي تعتمد على tz.local. لم يظهر هذا الخلل سابقاً
    // لأن دالة الجدولة (_scheduleNotification) لم تكن تُستدعى من أي
    // مكان في الواجهة بعد. بما أن التطبيق مخصص للعراق (منطقة زمنية
    // واحدة)، نحدد المنطقة صراحة.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));

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

    // ✅ يطلب استثناء التطبيق من "تحسين البطارية" عبر نافذة نظام قياسية
    // في أندرويد نفسها (وليست مساراً يدوياً في إعدادات الجهاز). هذا
    // إذن معياري (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) يعمل على معظم
    // الأجهزة بما فيها شاومي وهواوي وسامسونج، ويحل محل الاعتماد الكامل
    // على تعليمات نصية يدوية طويلة كانت تُعرض للمستخدم سابقاً في هذه
    // الشاشة. لا يُطلب إلا إن لم يكن ممنوحاً بالفعل، ولا يُعرض له أي
    // رسالة فشل إن رفضه المستخدم أو لم يدعمه الجهاز - فهو تحسين إضافي
    // وليس شرطاً لعمل باقي ميزات الإشعارات الأساسية.
    try {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
      if (!batteryStatus.isGranted) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } catch (e) {
      debugPrint('تعذّر طلب استثناء تحسين البطارية: $e');
    }
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

  // ==================== تذكير المناسبات التلقائي ====================
  //
  // آلية العمل: نجلب جدول الأشهر الهجرية المنشور فعلياً (نفس مصدر شارة
  // التاريخ الهجري في الشاشة الرئيسية)، ثم لكل مناسبة في ahlulBaytEvents
  // نستخرج اليوم والشهر من الرواية الأشهر (isMostFamous)، ونطابقها مع
  // الجدول لحساب التاريخ الميلادي الفعلي، ثم نجدول إشعاراً في الساعة 8
  // صباحاً من ذلك اليوم. أي مناسبة يقع شهرها خارج الجدول المنشور حالياً
  // (عادة أشهر بعيدة لم تُعلن رؤية هلالها بعد) تُتجاهل بصمت هذه الدورة،
  // وستُطابَق تلقائياً في المرة القادمة التي يُحدَّث فيها الجدول ويُعاد
  // تشغيل الجدولة (انظر _loadSettings أعلاه).

  /// نطاق مُعرّفات إشعارات المناسبات (لتفادي التصادم مع قنوات أخرى،
  /// ولتمكين إلغائها تحديداً دون التأثير على إشعارات الأذان مثلاً).
  static const int _eventsNotificationIdBase = 5000;

  /// أسماء الأشهر الهجرية كما تظهر بالضبط في hijri_calendar.json، مرتبة
  /// من الأطول فالأقصر لتفادي تطابق جزئي خاطئ (مثال: "ربيع الأول" يجب
  /// أن يُفحص قبل "ربيع" لو وُجد استخدام مختصر لاحقاً).
  static const List<String> _calendarMonthNames = [
    'جمادى الأولى',
    'جمادى الآخرة',
    'ربيع الأول',
    'ربيع الآخر',
    'ذو القعدة',
    'ذو الحجة',
    'محرم',
    'صفر',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
  ];

  /// بعض المناسبات في ahlulbayt_dates_data.dart تستخدم تسميات مرادفة
  /// لنفس الشهر تختلف عن التسمية المعتمدة في hijri_calendar.json
  /// (مثال: "ربيع الثاني" هو نفسه "ربيع الآخر"). هذا القاموس يوحّدها.
  static const Map<String, String> _monthNameSynonyms = {
    'ربيع الثاني': 'ربيع الآخر',
  };

  /// يحاول استخراج رقم اليوم الهجري من نص الرواية (hijriDate)، بالبحث
  /// عن رقم يسبق مباشرة اسم شهر معروف من _calendarMonthNames (بعد توحيد
  /// المرادفات). يتعامل مع صيغ مثل "10 محرم (يوم عاشوراء)" و
  /// "آخر يوم من صفر (29 صفر)" لأن الرقم يظهر قبل اسم الشهر في كلتا
  /// الحالتين. يُعيد null إن لم يوجد رقم يوم محدد (مثل "غير محدد بدقة").
  ({int day, String monthName})? _extractDayAndMonth(String hijriDateRaw) {
    var text = hijriDateRaw;
    for (final entry in _monthNameSynonyms.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    for (final monthName in _calendarMonthNames) {
      final pattern = RegExp('(\\d{1,2})\\s*' + RegExp.escape(monthName));
      final match = pattern.firstMatch(text);
      if (match != null) {
        final day = int.tryParse(match.group(1)!);
        if (day != null && day >= 1 && day <= 30) {
          return (day: day, monthName: monthName);
        }
      }
    }
    return null;
  }

  /// يحوّل يوم+شهر هجري إلى تاريخ ميلادي فعلي، بالبحث عن الشهر المطابق
  /// ضمن جدول الأشهر المنشور. يُعيد null إن لم يكن الشهر منشوراً بعد.
  DateTime? _hijriToGregorian(
      int day, String monthName, List<HijriMonthEntry> months) {
    for (final month in months) {
      if (month.name == monthName && day <= month.days) {
        return month.startDate.add(Duration(days: day - 1));
      }
    }
    return null;
  }

  /// يجدول إشعاراً واحداً لمناسبة معيّنة في الساعة 8 صباحاً من تاريخها.
  Future<void> _scheduleEventNotification({
    required int id,
    required AhlulBaytEvent event,
    required DateTime gregorianDate,
  }) async {
    final scheduledTime = DateTime(
      gregorianDate.year,
      gregorianDate.month,
      gregorianDate.day,
      8, // الساعة 8 صباحاً
    );

    // لا تجدول تاريخاً فات بالفعل
    if (scheduledTime.isBefore(DateTime.now())) return;

    final isBirth = event.kind == EventKind.birth;
    final title = isBirth
        ? 'ذكرى ولادة ${event.personName}'
        : 'ذكرى استشهاد/وفاة ${event.personName}';

    const androidDetails = AndroidNotificationDetails(
      'events_channel_v1',
      'تذكير المناسبات',
      channelDescription: 'تذكير تلقائي بولادات ووفيات أهل البيت عليهم السلام',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      event.description,
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// ✅ الدالة الرئيسية: تمر على كل مناسبات أهل البيت، تطابق كل واحدة مع
  /// التاريخ الميلادي الفعلي عبر الجدول المنشور، وتجدول إشعاراً لكل ما
  /// أمكن مطابقته ولم يفت وقته بعد.
  Future<void> _scheduleEventsReminders() async {
    final months = await HijriCalendarService.getMonths();
    if (months.isEmpty) return; // لا يوجد اتصال ولا نسخة مخزّنة محلياً

    for (var i = 0; i < ahlulBaytEvents.length; i++) {
      final event = ahlulBaytEvents[i];
      if (event.narrations.isEmpty) continue;

      final famousNarration = event.narrations.firstWhere(
        (n) => n.isMostFamous,
        orElse: () => event.narrations.first,
      );

      final parsed = _extractDayAndMonth(famousNarration.hijriDate);
      if (parsed == null) continue; // لا يوجد يوم محدد بدقة لهذه المناسبة

      final gregorianDate =
          _hijriToGregorian(parsed.day, parsed.monthName, months);
      if (gregorianDate == null) continue; // الشهر خارج الجدول المنشور حالياً

      await _scheduleEventNotification(
        id: _eventsNotificationIdBase + i,
        event: event,
        gregorianDate: gregorianDate,
      );
    }
  }

  /// يلغي فقط إشعارات المناسبات المجدولة (دون التأثير على إشعارات
  /// الأذان أو غيرها)، لأن معرّفاتها كلها ضمن نطاق ثابت معروف.
  Future<void> _cancelEventsReminders() async {
    for (var i = 0; i < ahlulBaytEvents.length; i++) {
      await _notificationsPlugin.cancel(_eventsNotificationIdBase + i);
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


  String _getHijriDate(AhlulBaytEvent event) {
    if (event.narrations.isEmpty) return '';
    final famousNarration = event.narrations.firstWhere(
      (n) => n.isMostFamous,
      orElse: () => event.narrations.first,
    );
    return famousNarration.hijriDate;
  }

  void _showReminderDialog() {
    final allEvents = _getUpcomingEvents();
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
        final hijriDate = _getHijriDate(event);
        return ListTile(
          leading: Icon(
            event.kind == EventKind.birth ? Icons.brightness_5 : Icons.brightness_2,
            color: event.kind == EventKind.birth
                ? AppColors.primaryGreen
                : Colors.grey[700],
          ),
          title: Text(event.personName),
          subtitle: Text(
            '${event.kind == EventKind.birth ? 'ولادة' : 'وفاة/استشهاد'} - $hijriDate',
          ),
          trailing: IconButton(
            icon: const Icon(Icons.notifications_active, color: AppColors.primaryGreen),
            onPressed: () {
              _showInstantNotification(
                'تذكير: ${event.personName}',
                '${event.kind == EventKind.birth ? 'ولادة' : 'وفاة/استشهاد'} ${event.personName} - $hijriDate',
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

  List<AhlulBaytEvent> _getUpcomingEvents() {
    return ahlulBaytEvents.toList();
  }

  Future<void> _shareToWhatsApp() async {
    final text = Uri.encodeComponent(
      '''حمل تطبيق دليل الزائر - تطبيق ديني شيعي شامل
يحتوي على: مواقيت الصلاة - أقوال وخطب - أسئلة شرعية - خريطة العراق - اتجاه القبلة
حصراً على المذهب الشيعي'''
    );
    final url = Uri.parse('https://wa.me/?text=$text');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _shareToTelegram() async {
    final text = Uri.encodeComponent(
      '''حمل تطبيق دليل الزائر - تطبيق ديني شامل
يحتوي على: مواقيت الصلاة - أقوال وخطب - أسئلة شرعية - خريطة العراق - اتجاه القبلة
حصراً على المذهب الشيعي'''
    );
    final url = Uri.parse('https://t.me/share/url?url=&text=$text');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _shareGeneral() {
    Clipboard.setData(const ClipboardData(
      text: '''حمل تطبيق دليل الزائر - تطبيق ديني شامل
يحتوي على: مواقيت الصلاة - أقوال وخطب - أسئلة شرعية - خريطة العراق - اتجاه القبلة
حصراً على المذهب الشيعي
https://github.com/daleelzuwar/alhussein''',
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ نص المشاركة - الصقه في أي تطبيق'),
        duration: Duration(seconds: 3),
      ),
    );
  }

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
              'انشر دليل الزائر مع أصدقائك وعائلتك',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.primaryGreen),
              title: const Text('نسخ رابط التطبيق'),
              subtitle: const Text('انسخ الرابط والصقه في أي مكان'),
              onTap: () {
                Clipboard.setData(const ClipboardData(
                  text: '''حمل تطبيق دليل الزائر - تطبيق ديني حسيني شامل
يحتوي على: مواقيت الصلاة - أقوال وخطب - أسئلة شرعية - المسار الاقرب على الخرائط - اتجاه القبلة - اتجاة المعصومين والاماكن المقدسة - خطب واقوال اهل البيت - كتب دينية
حصراً على المذهب الشيعي الإثني عشري
https://github.com/daleelzuwar/alhussein''',
                ));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ نص المشاركة')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.message, color: Color(0xFF25D366)),
              title: const Text('واتساب'),
              onTap: () {
                Navigator.pop(context);
                _shareToWhatsApp();
              },
            ),
            ListTile(
              leading: const Icon(Icons.send, color: Color(0xFF0088cc)),
              title: const Text('تليجرام'),
              onTap: () {
                Navigator.pop(context);
                _shareToTelegram();
              },
            ),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
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
                    'دليل الزائر',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'تطبيق ديني شامل يهدف إلى خدمة زوار المراقد والاماكن المقدسة '
                    'وتوفير المعلومات الشرعية والتاريخية والخدمية لهم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
            title: 'دليل الزائر',
            subtitle: 'حدد موقعك لمعرفة المسافة إلى المراقد والاماكن المقدسة وفتح الخريطة',
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

          const Text(
            'الإشعارات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

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
                    _saveSetting('prayerTimeReminder', false);
                    _saveSetting('eventsReminder', false);
                    _saveSetting('muharramReminder', false);
                    _cancelAllNotifications();
                  }
                },
                activeColor: AppColors.primaryGreen,
              ),
            ),
          ),

          _NotificationTile(
            icon: Icons.access_time,
            title: 'تذكير مواقيت الصلاة',
            subtitle: 'إشعار عند دخول وقت الأذان',
            enabled: _notificationsEnabled && _prayerTimeReminder,
            onChanged: _notificationsEnabled
                ? (value) async {
                    setState(() => _prayerTimeReminder = value);
                    await _saveSetting('prayerTimeReminder', value);
                  }
                : null,
          ),

          // ✅ قسم صوت الأذان الجديد: نمط التنبيه (صوت/اهتزاز/صامت)
          // + مستوى صوت معاينة داخل التطبيق
          if (_notificationsEnabled && _prayerTimeReminder) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.volume_up, color: AppColors.primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'نمط تنبيه الأذان',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('🔊 صوت'),
                          selected: _adhanSoundMode == 'sound',
                          selectedColor: AppColors.primaryGreen,
                          labelStyle: TextStyle(
                            color: _adhanSoundMode == 'sound' ? Colors.white : Colors.black87,
                            fontWeight: _adhanSoundMode == 'sound' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => _saveAdhanSoundMode('sound'),
                        ),
                        ChoiceChip(
                          label: const Text('📳 اهتزاز فقط'),
                          selected: _adhanSoundMode == 'vibrate',
                          selectedColor: AppColors.primaryGreen,
                          labelStyle: TextStyle(
                            color: _adhanSoundMode == 'vibrate' ? Colors.white : Colors.black87,
                            fontWeight: _adhanSoundMode == 'vibrate' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => _saveAdhanSoundMode('vibrate'),
                        ),
                        ChoiceChip(
                          label: const Text('🔕 صامت'),
                          selected: _adhanSoundMode == 'silent',
                          selectedColor: AppColors.primaryGreen,
                          labelStyle: TextStyle(
                            color: _adhanSoundMode == 'silent' ? Colors.white : Colors.black87,
                            fontWeight: _adhanSoundMode == 'silent' ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) => _saveAdhanSoundMode('silent'),
                        ),
                      ],
                    ),
                    if (_adhanSoundMode == 'sound') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'اختر مقطع الأذان',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          _AdhanSoundOption(
                            label: 'الصوت الأول',
                            selected: _adhanSoundFile == 'adhan1',
                            onSelect: () => _saveAdhanSoundFile('adhan1'),
                            onPreview: () => _previewAdhanSound('adhan1'),
                          ),
                          const SizedBox(height: 6),
                          _AdhanSoundOption(
                            label: 'الصوت الثاني',
                            selected: _adhanSoundFile == 'adhan2',
                            onSelect: () => _saveAdhanSoundFile('adhan2'),
                            onPreview: () => _previewAdhanSound('adhan2'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'مستوى صوت المعاينة داخل التطبيق',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.volume_down, size: 18, color: Colors.grey),
                          Expanded(
                            child: Slider(
                              value: _adhanVolume,
                              min: 0.0,
                              max: 1.0,
                              activeColor: AppColors.primaryGreen,
                              onChanged: (v) {
                                setState(() => _adhanVolume = v);
                                _applyLiveVolumePreview(v);
                              },
                              onChangeEnd: (v) => _saveAdhanVolume(v),
                            ),
                          ),
                          const Icon(Icons.volume_up, size: 18, color: Colors.grey),
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill, color: AppColors.primaryGreen),
                            tooltip: 'تجربة الصوت المختار',
                            onPressed: () => _previewAdhanSound(_adhanSoundFile),
                          ),
                        ],
                      ),
                      Text(
                        'الشريط أعلاه يتحكم بصوت أزرار "▶ تجربة" داخل التطبيق فقط.\n'
                        'صوت إشعار الأذان الفعلي عند إغلاق التطبيق يتبع مستوى '
                        'صوت الإشعارات في إعدادات الجهاز نفسه (قيد تحكم أندرويد) - '
                        'يمكنك ضبطه من: إعدادات الهاتف ← التطبيقات ← دليل الزائر ← الإشعارات.',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.6),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          _NotificationTile(
            icon: Icons.calendar_today,
            title: 'تذكير المناسبات التلقائي',
            subtitle: 'ولادات ووفيات أهل البيت حسب التاريخ',
            enabled: _notificationsEnabled && _eventsReminder,
            onChanged: _notificationsEnabled
                ? (value) async {
                    setState(() => _eventsReminder = value);
                    await _saveSetting('eventsReminder', value);

                    if (value) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('جاري جدولة تذكيرات المناسبات...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      await _scheduleEventsReminders();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تفعيل تذكير المناسبات'),
                          ),
                        );
                      }
                    } else {
                      await _cancelEventsReminders();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم إلغاء تذكير المناسبات'),
                          ),
                        );
                      }
                    }
                  }
                : null,
          ),

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

          _NotificationTile(
            icon: Icons.mosque,
            title: 'تذكير أيام محرم',
            subtitle: 'إشعار قبل أيام عاشوراء',
            enabled: _notificationsEnabled && _muharramReminder,
            onChanged: _notificationsEnabled
                ? (value) async {
                    setState(() => _muharramReminder = value);
                    await _saveSetting('muharramReminder', value);
                  }
                : null,
          ),

          const SizedBox(height: 16),

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
                        'دليل الزائر',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تطبيق ديني حسيني شامل يهدف إلى خدمة زوار المراقد والاماكن المقدسة وتوفير '
                    'المعلومات الشرعية والتاريخية والخدمية لهم.',
                    style: TextStyle(fontSize: 13, height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'المميزات:',
                    style: TextStyle(fontSize: 12, height: 1.8),
                  ),
                  const Text(
                    '• مواقيت الصلاة حسب كراس السيد السيستاني دام ظله',
                    style: TextStyle(fontSize: 12, height: 1.8),
                  ),
                  const Text(
                    '• أقوال وخطب الإمام الحسين عليه السلام',
                    style: TextStyle(fontSize: 12, height: 1.8),
                  ),
                  const Text(
                    '• أسئلة شرعية وفتاوى',
                    style: TextStyle(fontSize: 12, height: 1.8),
                  ),
                  const Text(
                    '• تواريخ ولادات ووفيات أهل البيت عليهم السلام',
                    style: TextStyle(fontSize: 12, height: 1.8),
                  ),
                  const Text(
                    '• خريطة تفاعلية للأماكن المقدسة',
                    style: TextStyle(fontSize: 12, height: 1.8),
                  ),
                  const Text(
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
                      Text('فريق دليل الزائر'),
                    ],
                  ),
                ],
              ),
            ),
          ),

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
                    'subject': 'اقتراح/ملاحظة - دليل الزائر',
                  },
                );
                await launchUrl(emailUri);
              },
            ),
          ),

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

class _AdhanSoundOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onPreview;

  const _AdhanSoundOption({
    required this.label,
    required this.selected,
    required this.onSelect,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : Colors.grey[300]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primaryGreen : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline, color: AppColors.primaryGreen),
              tooltip: 'تجربة $label',
              onPressed: onPreview,
            ),
          ],
        ),
      ),
    );
  }
}

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
