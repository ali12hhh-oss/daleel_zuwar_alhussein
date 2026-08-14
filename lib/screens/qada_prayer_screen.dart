import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../services/qada_prayer_service.dart';
import '../theme.dart';

class QadaPrayerScreen extends StatefulWidget {
  const QadaPrayerScreen({super.key});

  @override
  State<QadaPrayerScreen> createState() => _QadaPrayerScreenState();
}

class _QadaPrayerScreenState extends State<QadaPrayerScreen> {
  static const List<_PrayerInfo> _prayers = <_PrayerInfo>[
    _PrayerInfo('fajr', 'الفجر', Icons.wb_twilight),
    _PrayerInfo('dhuhr', 'الظهر', Icons.wb_sunny),
    _PrayerInfo('asr', 'العصر', Icons.sunny),
    _PrayerInfo('maghrib', 'المغرب', Icons.wb_twilight),
    _PrayerInfo('isha', 'العشاء', Icons.nightlight_round),
  ];

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Map<String, dynamic> _data = QadaPrayerService.defaultData();
  bool _loading = true;
  bool _showLog = true;
  bool _showStats = false;
  bool _notificationsReady = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await QadaPrayerService.load();
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
    await _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Baghdad'));
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _notifications.initialize(settings);
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      _notificationsReady = true;
      if (_boolValue('reminderEnabled')) {
        await _scheduleReminder();
      }
    } catch (_) {
      _notificationsReady = false;
    }
  }

  int _intValue(String key, [int fallback = 0]) {
    final value = _data[key];
    return value is num ? value.toInt() : fallback;
  }

  bool _boolValue(String key) => _data[key] == true;
  /// يحول الأرقام التي تظهر للمستخدم إلى أرقام عربية شرقية.
  String _arabicDigits(Object value) {
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    var text = value.toString();
    for (var i = 0; i < western.length; i++) {
      text = text.replaceAll(western[i], eastern[i]);
    }
    return text;
  }

  String _arabicNumber(num value) => _arabicDigits(value);

  int _parseUserInt(String value, [int fallback = 0]) {
    var text = value.trim();
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    const western = '0123456789';
    for (var i = 0; i < eastern.length; i++) {
      text = text.replaceAll(eastern[i], western[i]);
    }
    return int.tryParse(text) ?? fallback;
  }

  Map<String, dynamic> get _manualCompleted {
    final raw = _data['manualCompleted'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  int _manualCompletedFor(String prayerKey) {
    final value = _manualCompleted[prayerKey];
    return value is num ? value.toInt() : 0;
  }

  List<Map<String, dynamic>> get _events {
    final raw = _data['events'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return <Map<String, dynamic>>[];
  }


  Map<String, dynamic> get _targets {
    final raw = _data['targets'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Map<String, dynamic> get _checks {
    final raw = _data['checks'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Future<void> _persist() async {
    await QadaPrayerService.save(_data);
    if (mounted) setState(() {});
  }

  bool _isChecked(int day, String prayerKey) {
    return _checks['$day-$prayerKey'] == true;
  }

  int _completedFor(String prayerKey) {
    var count = _manualCompletedFor(prayerKey);
    for (var day = 0; day < _intValue('days', 30); day++) {
      if (_isChecked(day, prayerKey)) count++;
    }
    return count;
  }

  int get _completedTotal {
    var total = 0;
    for (final prayer in _prayers) {
      total += _completedFor(prayer.key);
    }
    return total;
  }

  int get _targetTotal {
    return _prayers.fold<int>(0, (sum, prayer) {
      final value = _targets[prayer.key];
      return sum + (value is num ? value.toInt() : 0);
    });
  }

  int get _remainingTotal => (_targetTotal - _completedTotal).clamp(0, 1 << 30).toInt();

  double get _progress {
    if (_targetTotal <= 0) return 0;
    return (_completedTotal / _targetTotal).clamp(0.0, 1.0).toDouble();
  }

  int get _todayCompleted {
    final now = DateTime.now();
    final day = _dayIndexForDate(now);
    var total = 0;
    if (day >= 0 && day < _intValue('days', 30)) {
      total += _prayers.where((p) => _isChecked(day, p.key)).length;
    }
    for (final event in _events) {
      final raw = DateTime.tryParse(event['date']?.toString() ?? '');
      if (raw != null && raw.year == now.year && raw.month == now.month && raw.day == now.day) {
        total++;
      }
    }
    return total;
  }

  int _dayIndexForDate(DateTime date) {
    final raw = DateTime.tryParse(_data['startDate']?.toString() ?? '');
    if (raw == null) return -1;
    final start = DateTime(raw.year, raw.month, raw.day);
    final current = DateTime(date.year, date.month, date.day);
    return current.difference(start).inDays;
  }

  DateTime _dateForDay(int day) {
    final raw = DateTime.tryParse(_data['startDate']?.toString() ?? '') ?? DateTime.now();
    final start = DateTime(raw.year, raw.month, raw.day);
    return start.add(Duration(days: day));
  }

  Future<void> _registerQadaPrayer() async {
    if (_targetTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل أولًا إجمالي الصلوات الفائتة لكل صلاة.')),
      );
      return;
    }
    if (_remainingTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد صلوات متبقية حسب الأعداد المسجلة حاليًا.')),
      );
      return;
    }
    _PrayerInfo? selected = _prayers.first;
    final result = await showDialog<_PrayerInfo>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('تسجيل صلاة قضاء', textDirection: TextDirection.rtl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: Text('اختر الصلاة التي أديتها قضاءً:'),
              ),
              const SizedBox(height: 10),
              ..._prayers.map((prayer) => RadioListTile<_PrayerInfo>(
                    value: prayer,
                    groupValue: selected,
                    onChanged: (value) => dialogSetState(() => selected = value),
                    title: Text(prayer.name, textDirection: TextDirection.rtl),
                    secondary: Icon(prayer.icon),
                  )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, selected),
              icon: const Icon(Icons.check),
              label: const Text('تم قضاء الصلاة'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final selectedTarget = (_targets[result.key] is num ? (_targets[result.key] as num).toInt() : 0);
    if (_completedFor(result.key) >= selectedTarget) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا توجد صلوات ${result.name} متبقية حسب العدد المسجل لها.')),
        );
      }
      return;
    }

    final manual = _manualCompleted;
    manual[result.key] = _manualCompletedFor(result.key) + 1;
    _data['manualCompleted'] = manual;

    final events = _events;
    events.insert(0, <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'prayer': result.key,
      'prayerName': result.name,
      'date': DateTime.now().toIso8601String(),
      'source': 'direct',
    });
    if (events.length > 1000) events.removeRange(1000, events.length);
    _data['events'] = events;
    await _persist();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تسجيل قضاء ${result.name} بنجاح. تقبل الله منك 🤍')),
    );
  }

  Future<void> _toggleCheck(int day, _PrayerInfo prayer) async {
    final key = '$day-${prayer.key}';
    final currentlyChecked = _isChecked(day, prayer.key);

    if (currentlyChecked) {
      final remove = await _confirm(
        title: 'إزالة علامة القضاء؟',
        message: 'سيتم إزالة تسجيل ${prayer.name} من اليوم ${_arabicNumber(day + 1)}.',
        confirmText: 'إزالة العلامة',
      );
      if (!remove) return;
    }

    final checks = _checks;
    if (currentlyChecked) {
      checks.remove(key);
    } else {
      checks[key] = true;
    }
    _data['checks'] = checks;
    await _persist();
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textDirection: TextDirection.rtl),
        content: Text(message, textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _data['personName']?.toString() ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اسم الشخص', textDirection: TextDirection.rtl),
        content: TextField(
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'اختياري',
            hintText: 'مثال: محمد',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('حفظ')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    _data['personName'] = value;
    await _persist();
  }

  Future<void> _changeTarget(_PrayerInfo prayer, int delta) async {
    final targets = _targets;
    final current = (targets[prayer.key] is num ? (targets[prayer.key] as num).toInt() : 0);
    final minimum = _completedFor(prayer.key);
    final next = (current + delta).clamp(minimum, 1000000).toInt();
    targets[prayer.key] = next;
    _data['targets'] = targets;
    await _persist();
  }

  Future<void> _configureTargets() async {
    final controllers = <String, TextEditingController>{};
    for (final prayer in _prayers) {
      controllers[prayer.key] = TextEditingController(
        text: _arabicNumber(_targets[prayer.key] is num ? _targets[prayer.key] : 0),
      );
    }

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إجمالي الصلوات الفائتة', textDirection: TextDirection.rtl),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: _prayers.map((prayer) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: controllers[prayer.key],
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: prayer.name,
                      prefixIcon: Icon(prayer.icon),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final values = <String, int>{};
              for (final prayer in _prayers) {
                values[prayer.key] = _parseUserInt(controllers[prayer.key]!.text.trim());
              }
              Navigator.pop(context, values);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (result == null) return;
    _data['targets'] = result;
    await _persist();
  }

  Future<void> _configureDays() async {
    final controller = TextEditingController(text: _arabicNumber(_intValue('days', 30)));
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عدد أيام السجل', textDirection: TextDirection.rtl),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            labelText: 'من 1 إلى 3650 يومًا',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(context, _parseUserInt(controller.text.trim())),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    final days = result.clamp(1, 3650).toInt();
    _data['days'] = days;
    await _persist();
  }

  Future<void> _configurePlan() async {
    var enabled = _boolValue('planEnabled');
    final controller = TextEditingController(text: _arabicNumber(_intValue('planDaily', 5)));
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('خطة القضاء', textDirection: TextDirection.rtl),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile.adaptive(
                value: enabled,
                title: const Text('تفعيل خطة يومية', textDirection: TextDirection.rtl),
                onChanged: (value) => dialogSetState(() => enabled = value),
              ),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'عدد الصلوات المستهدفة يوميًا',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'يمكنك تغيير العدد في أي وقت، ولا يؤثر ذلك على السجل المنجز.',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () => Navigator.pop(context, <String, dynamic>{
                'enabled': enabled,
                'daily': _parseUserInt(controller.text.trim()) ?? 5,
              }),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null) return;
    _data['planEnabled'] = result['enabled'] == true;
    if (result['daily'] is num) _data['planDaily'] = (result['daily'] as num).toInt().clamp(1, 50).toInt();
    await _persist();
  }

  Future<void> _configureReminder() async {
    final initial = TimeOfDay(hour: _intValue('reminderHour', 21), minute: _intValue('reminderMinute', 0));
    final time = await showTimePicker(context: context, initialTime: initial);
    if (time == null) return;
    _data['reminderEnabled'] = true;
    _data['reminderHour'] = time.hour;
    _data['reminderMinute'] = time.minute;
    await _persist();
    await _scheduleReminder();
  }

  Future<void> _scheduleReminder() async {
    if (!_notificationsReady) return;
    try {
      await _notifications.cancel(8301);
      if (!_boolValue('reminderEnabled')) return;
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        _intValue('reminderHour', 21),
        _intValue('reminderMinute', 0),
      );
      if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'qada_prayer_channel',
          'تذكير قضاء الصلاة',
          channelDescription: 'تذكير يومي لمتابعة قضاء الصلاة',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );
      await _notifications.zonedSchedule(
        8301,
        'قضاء الصلاة',
        'تذكّر متابعة صلوات القضاء المسجلة في دليل زوار الحسين.',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // لا نعطل القسم إذا تعذر تشغيل التنبيه.
    }
  }

  Future<void> _disableReminder() async {
    _data['reminderEnabled'] = false;
    await _persist();
    if (_notificationsReady) await _notifications.cancel(8301);
  }

  Future<File> _createBackupFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final safeName = (_data['personName']?.toString().trim().isNotEmpty ?? false)
        ? _data['personName'].toString().trim().replaceAll(RegExp(r'[^\u0600-\u06FF\w\- ]'), '_')
        : 'qada';
    final file = File('${directory.path}/qada_prayer_${safeName}_${DateTime.now().millisecondsSinceEpoch}.json');
    final payload = <String, dynamic>{
      'app': 'دليل زوار الحسين',
      'backupType': 'qada_prayer',
      'createdAt': DateTime.now().toIso8601String(),
      'data': _data,
    };
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload), flush: true);
    return file;
  }

  Future<void> _backup() async {
    try {
      final file = await _createBackupFile();
      await Share.shareXFiles([XFile(file.path)], text: 'نسخة احتياطية لسجل قضاء الصلاة');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء النسخة الاحتياطية. يمكنك حفظها على الهاتف أو إرسالها لنفسك.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر إنشاء النسخة الاحتياطية: $e')));
    }
  }

  Future<void> _restore() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      String raw;
      if (picked.bytes != null) {
        raw = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        raw = await File(picked.path!).readAsString();
      } else {
        throw Exception('تعذر قراءة الملف المختار.');
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['data'] is! Map) {
        throw Exception('هذا الملف ليس نسخة صحيحة من سجل قضاء الصلاة.');
      }
      final confirmed = await _confirm(
        title: 'استعادة النسخة الاحتياطية؟',
        message: 'سيتم استبدال السجل الحالي بالبيانات الموجودة في الملف.',
        confirmText: 'استعادة',
      );
      if (!confirmed) return;
      _data = Map<String, dynamic>.from(decoded['data'] as Map);
      await _persist();
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت استعادة سجل قضاء الصلاة بنجاح.')));
      }
      if (_boolValue('reminderEnabled')) await _scheduleReminder();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر استعادة النسخة: $e')));
    }
  }

  Future<void> _resetAll() async {
    final confirmed = await _confirm(
      title: 'مسح سجل قضاء الصلاة؟',
      message: 'سيتم حذف الاسم والعدادات وعلامات الإنجاز والإعدادات المحلية.',
      confirmText: 'مسح السجل',
    );
    if (!confirmed) return;
    await QadaPrayerService.clear();
    _data = QadaPrayerService.defaultData();
    if (_notificationsReady) await _notifications.cancel(8301);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('قضاء الصلاة'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'النسخ الاحتياطي',
            onPressed: _backup,
            icon: const Icon(Icons.save_alt),
          ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            _buildHeader(dark),
            const SizedBox(height: 12),
            _buildSummary(dark),
            const SizedBox(height: 12),
            _buildPrayerCounters(dark),
            const SizedBox(height: 12),
            _buildExtraPrayerCard(dark),
            const SizedBox(height: 12),
            _buildDirectRegisterCard(dark),
            const SizedBox(height: 12),
            _buildPlanCard(dark),
            const SizedBox(height: 12),
            _buildLogCard(dark),
            const SizedBox(height: 12),
            _buildHistoryCard(dark),
            const SizedBox(height: 12),
            _buildToolsCard(dark),
            const SizedBox(height: 12),
            _buildStatsCard(dark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool dark) {
    final name = _data['personName']?.toString().trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mosque, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('سجل قضاء الصلاة', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(
                  name.isEmpty ? 'اسم الشخص اختياري' : 'السجل باسم: $name',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _editName,
            color: Colors.white,
            icon: const Icon(Icons.edit),
            tooltip: 'تعديل الاسم',
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(bool dark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _statBox('المتبقي', _arabicNumber(_remainingTotal), Icons.pending_actions, Colors.orange.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _statBox('المنجز', _arabicNumber(_completedTotal), Icons.check_circle, Colors.green.shade700)),
                const SizedBox(width: 8),
                Expanded(child: _statBox('نسبة الإنجاز', '${_arabicDigits((_progress * 100).toStringAsFixed(1))}٪', Icons.percent, AppColors.primaryGreen)),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(value: _progress, minHeight: 10),
            ),
            const SizedBox(height: 8),
            Text(
              _targetTotal == 0 ? 'أدخل إجمالي الصلوات الفائتة لبدء حساب المتبقي ونسبة الإنجاز.' : 'أنجزت ${_arabicNumber(_completedTotal)} من أصل ${_arabicNumber(_targetTotal)} صلاة.',
              textAlign: TextAlign.center,
              style: TextStyle(color: dark ? Colors.white70 : Colors.black87, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPrayerCounters(bool dark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('إجمالي الصلوات الفائتة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                OutlinedButton.icon(onPressed: _configureTargets, icon: const Icon(Icons.edit, size: 18), label: const Text('تعديل')),
              ],
            ),
            const SizedBox(height: 8),
            ..._prayers.map((prayer) {
              final target = (_targets[prayer.key] is num ? _targets[prayer.key] as num : 0).toInt();
              final done = _completedFor(prayer.key);
              final remaining = (target - done).clamp(0, 1 << 30);
              return Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(prayer.icon, color: AppColors.primaryGreen),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(prayer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('تم ${_arabicNumber(done)} • ${_arabicNumber(remaining)} متبقي', style: TextStyle(color: dark ? Colors.white70 : Colors.black87, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'إنقاص',
                      onPressed: () => _changeTarget(prayer, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 38),
                      alignment: Alignment.center,
                      child: Text(_arabicNumber(target), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    ),
                    IconButton(
                      tooltip: 'زيادة',
                      onPressed: () => _changeTarget(prayer, 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectRegisterCard(bool dark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('تسجيل صلاة قضاء', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(
              'بعد أداء الصلاة اضغط الزر وسجلها فورًا، وسيتم حفظها في السجل المحلي.',
              style: TextStyle(fontSize: 12, color: dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _registerQadaPrayer,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('تم قضاء صلاة'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(bool dark) {
    final events = _events;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('سجل الإنجاز حسب التاريخ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                if (events.isNotEmpty)
                  TextButton.icon(
                    onPressed: _clearHistory,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('مسح السجل'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'كل صلاة تسجلها من زر «تم قضاء صلاة» تظهر هنا مع تاريخ ووقت الإنجاز.',
              style: TextStyle(fontSize: 12, color: dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 10),
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: Text('لا توجد عمليات قضاء مسجلة بعد.')),
              )
            else
              ...events.take(30).map((event) {
                final date = DateTime.tryParse(event['date']?.toString() ?? '');
                final prayer = event['prayerName']?.toString() ?? 'الصلاة';
                return Container(
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 21),
                      const SizedBox(width: 9),
                      Expanded(child: Text('تم قضاء صلاة $prayer')),
                      if (date != null)
                        Text(
                          '${_formatDate(date)}\n${_formatTime(date)}',
                          textAlign: TextAlign.left,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                );
              }),
            if (events.length > 30)
              Text('يتم عرض آخر ${_arabicNumber(30)} عملية هنا، وتبقى جميع العمليات محفوظة.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _clearHistory() async {
    final confirmed = await _confirm(
      title: 'مسح سجل الإنجاز؟',
      message: 'سيتم حذف سجل العمليات المباشرة فقط. لن تتغير أعداد القضاء ولا جدول الأيام.',
      confirmText: 'مسح السجل',
    );
    if (!confirmed) return;
    _data['events'] = <dynamic>[];
    await _persist();
  }

  Widget _buildPlanCard(bool dark) {
    final enabled = _boolValue('planEnabled');
    final daily = _intValue('planDaily', 5);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12), child: const Icon(Icons.flag, color: AppColors.primaryGreen)),
              title: const Text('خطة القضاء', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(enabled ? 'هدفك اليومي: ${_arabicNumber(daily)} صلاة' : 'لم يتم تفعيل خطة يومية'),
              trailing: IconButton(onPressed: _configurePlan, icon: const Icon(Icons.tune)),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amount in <int>[1, 5, 10])
                  ChoiceChip(
                    label: Text(_arabicNumber(amount)),
                    selected: enabled && daily == amount,
                    onSelected: (_) async {
                      _data['planEnabled'] = true;
                      _data['planDaily'] = amount;
                      await _persist();
                    },
                  ),
                ChoiceChip(
                  label: const Text('مخصص'),
                  selected: enabled && !<int>[1, 5, 10].contains(daily),
                  onSelected: (_) => _configurePlan(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (enabled) ...[
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.today, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('خطة اليوم: ${_arabicNumber(_todayCompleted)} / ${_arabicNumber(daily)} صلوات')),
                  SizedBox(
                    width: 90,
                    child: LinearProgressIndicator(value: (_todayCompleted / daily).clamp(0.0, 1.0).toDouble()),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(bool dark) {
    final days = _intValue('days', 30);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('سجل الإنجاز اليومي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                IconButton(onPressed: _configureDays, icon: const Icon(Icons.calendar_month), tooltip: 'عدد الأيام'),
                Switch.adaptive(value: _showLog, onChanged: (v) => setState(() => _showLog = v)),
              ],
            ),
            Text('السجل الحالي: ${_arabicNumber(days)} يومًا — اضغط على المربع لتسجيل الصلاة.', style: TextStyle(fontSize: 12, color: dark ? Colors.white70 : Colors.black87)),
            if (_showLog) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 540,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildGrid(),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final days = _intValue('days', 30);
    const cellWidth = 70.0;
    return DataTable(
      columnSpacing: 4,
      headingRowHeight: 52,
      dataRowMinHeight: 58,
      dataRowMaxHeight: 64,
      columns: [
        const DataColumn(label: Text('اليوم', style: TextStyle(fontWeight: FontWeight.bold))),
        ..._prayers.map((p) => DataColumn(label: SizedBox(width: cellWidth, child: Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))))),
      ],
      rows: List<DataRow>.generate(days, (day) {
        final date = _dateForDay(day);
        return DataRow(
          cells: [
            DataCell(SizedBox(width: 80, child: Text('اليوم ${_arabicNumber(day + 1)}\n${_formatDate(date)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)))),
            ..._prayers.map((prayer) {
              final checked = _isChecked(day, prayer.key);
              return DataCell(
                SizedBox(
                  width: cellWidth,
                  child: Center(
                    child: InkWell(
                      onTap: () => _toggleCheck(day, prayer),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: checked ? AppColors.primaryGreen : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: checked ? AppColors.primaryGreen : Colors.grey.shade500, width: 1.5),
                        ),
                        child: Icon(checked ? Icons.check : Icons.add, size: 20, color: checked ? Colors.white : Colors.grey.shade600),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      }),
    );
  }

  String _formatDate(DateTime date) => '${_arabicNumber(date.day)}/${_arabicNumber(date.month)}/${_arabicNumber(date.year)}';

  String _formatTime(DateTime date) => '${_arabicNumber(date.hour.toString().padLeft(2, '0'))}:${_arabicDigits(date.minute.toString().padLeft(2, '0'))}';


  Map<String, dynamic> get _extraTotals {
    final raw = _data['extraTotals'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  Map<String, dynamic> get _extraCompleted {
    final raw = _data['extraCompleted'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  int _extraValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    return value is num ? value.toInt() : 0;
  }

  int _extraRemaining(String key) {
    return (_extraValue(_extraTotals, key) - _extraValue(_extraCompleted, key))
        .clamp(0, 1 << 30)
        .toInt();
  }

  Future<void> _configureExtraTypes() async {
    bool showQasr = _data['showQasr'] == true;
    bool showAyat = _data['showAyat'] == true;

    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إعدادات السجلات الإضافية'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  value: showQasr,
                  title: const Text('صلاة القصر'),
                  subtitle: const Text('إظهار سجل الظهر والعصر قصرًا بشكل مستقل'),
                  onChanged: (value) =>
                      setDialogState(() => showQasr = value ?? false),
                ),
                CheckboxListTile(
                  value: showAyat,
                  title: const Text('صلاة الآيات'),
                  subtitle: const Text('إظهار سجل مستقل لصلاة الآيات'),
                  onChanged: (value) =>
                      setDialogState(() => showAyat = value ?? false),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, {
                  'showQasr': showQasr,
                  'showAyat': showAyat,
                }),
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result == null) return;
    _data['showQasr'] = result['showQasr'] == true;
    _data['showAyat'] = result['showAyat'] == true;
    await _persist();
  }

  Future<void> _configureExtraTotals() async {
    final totals = _extraTotals;
    final controllers = <String, TextEditingController>{
      'qasrDhuhr': TextEditingController(
        text: _arabicNumber(_extraValue(totals, 'qasrDhuhr')),
      ),
      'qasrAsr': TextEditingController(
        text: _arabicNumber(_extraValue(totals, 'qasrAsr')),
      ),
      'qasrIsha': TextEditingController(
        text: _arabicNumber(_extraValue(totals, 'qasrIsha')),
      ),
      'ayat': TextEditingController(
        text: _arabicNumber(_extraValue(totals, 'ayat')),
      ),
    };

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إجمالي الصلوات الإضافية'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: controllers['qasrDhuhr'],
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'الظهر قصر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controllers['qasrAsr'],
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'العصر قصر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controllers['qasrIsha'],
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'العشاء قصر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controllers['ayat'],
                  keyboardType: TextInputType.number,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'صلاة الآيات',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'qasrDhuhr': _parseUserInt(controllers['qasrDhuhr']!.text),
                'qasrAsr': _parseUserInt(controllers['qasrAsr']!.text),
                'qasrIsha': _parseUserInt(controllers['qasrIsha']!.text),
                'ayat': _parseUserInt(controllers['ayat']!.text),
              }),
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    for (final controller in controllers.values) {
      controller.dispose();
    }
    if (result == null) return;

    final newTotals = _extraTotals;
    for (final entry in result.entries) {
      newTotals[entry.key] = entry.value < 0 ? 0 : entry.value;
    }
    _data['extraTotals'] = newTotals;
    await _persist();
  }

  Future<void> _recordExtraPrayer(String key, String label) async {
    final remaining = _extraRemaining(key);
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يوجد متبقٍ من $label حسب العدد المسجل.')),
      );
      return;
    }

    final completed = _extraCompleted;
    completed[key] = _extraValue(completed, key) + 1;
    _data['extraCompleted'] = completed;

    final events = _data['extraEvents'] is List
        ? List<dynamic>.from(_data['extraEvents'] as List)
        : <dynamic>[];
    events.insert(0, <String, dynamic>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'type': key,
      'name': label,
      'date': DateTime.now().toIso8601String(),
    });
    if (events.length > 1000) {
      events.removeRange(1000, events.length);
    }
    _data['extraEvents'] = events;
    await _persist();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تسجيل $label بنجاح.')),
    );
  }

  Future<void> _clearExtraHistory() async {
    final confirmed = await _confirm(
      title: 'مسح سجل الصلوات الإضافية؟',
      message: 'سيتم حذف سجل العمليات فقط، ولن تتغير الأعداد الإجمالية أو عدد المنجز.',
      confirmText: 'مسح السجل',
    );
    if (!confirmed) return;
    _data['extraEvents'] = <dynamic>[];
    await _persist();
  }

  Widget _buildExtraPrayerCard(bool dark) {
    final showQasr = _data['showQasr'] == true;
    final showAyat = _data['showAyat'] == true;

    if (!showQasr && !showAyat) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.tune),
          title: const Text(
            'سجلات صلاة القصر والآيات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'اختياري — فعّل ما تحتاجه من الإعدادات.',
            style: TextStyle(
              color: dark ? Colors.white70 : Colors.black87,
            ),
          ),
          trailing: const Icon(Icons.settings),
          onTap: _configureExtraTypes,
        ),
      );
    }

    final children = <Widget>[
      Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.primaryGreen),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'سجلات إضافية',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: _configureExtraTypes,
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            tooltip: 'تعديل الأعداد',
            onPressed: _configureExtraTotals,
            icon: const Icon(Icons.edit_note),
          ),
        ],
      ),
    ];

    if (showQasr) {
      children.addAll([
        _extraPrayerRow('الظهر قصر', 'qasrDhuhr', dark),
        _extraPrayerRow('العصر قصر', 'qasrAsr', dark),
        _extraPrayerRow('العشاء قصر', 'qasrIsha', dark),
      ]);
    }
    if (showAyat) {
      children.add(_extraPrayerRow('صلاة الآيات', 'ayat', dark));
    }

    final rawEvents = _data['extraEvents'];
    final events = rawEvents is List
        ? rawEvents.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    children.add(const Divider(height: 24));
    children.add(
      Row(
        children: [
          const Expanded(
            child: Text(
              'سجل الإنجاز الإضافي',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (events.isNotEmpty)
            TextButton(
              onPressed: _clearExtraHistory,
              child: const Text('مسح السجل'),
            ),
        ],
      ),
    );

    if (events.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'لا توجد عمليات مسجلة بعد.',
            textAlign: TextAlign.center,
            style: TextStyle(color: dark ? Colors.white70 : Colors.black87),
          ),
        ),
      );
    } else {
      children.addAll(
        events.take(20).map((event) {
          final date = DateTime.tryParse(event['date']?.toString() ?? '');
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(
              event['name']?.toString() ?? 'صلاة إضافية',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: date == null
                ? null
                : Text(
                    '${_formatDate(date)} — ${_formatTime(date)}',
                    style: TextStyle(
                      color: dark ? Colors.white70 : Colors.black87,
                    ),
                  ),
          );
        }),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _extraPrayerRow(String title, String key, bool dark) {
    final total = _extraValue(_extraTotals, key);
    final completed = _extraValue(_extraCompleted, key);
    final remaining = _extraRemaining(key);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.primaryGreen),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'الإجمالي ${_arabicNumber(total)} • المنجز ${_arabicNumber(completed)} • المتبقي ${_arabicNumber(remaining)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: dark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: remaining > 0 ? () => _recordExtraPrayer(key, title) : null,
            child: const Text('تم القضاء'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsCard(bool dark) {
    final reminderEnabled = _boolValue('reminderEnabled');
    final hour = _arabicDigits(_intValue('reminderHour', 21).toString().padLeft(2, '0'));
    final minute = _arabicDigits(_intValue('reminderMinute', 0).toString().padLeft(2, '0'));
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('اسم الشخص'),
            subtitle: Text((_data['personName']?.toString().trim().isEmpty ?? true) ? 'غير محدد — اختياري' : _data['personName'].toString()),
            trailing: const Icon(Icons.edit),
            onTap: _editName,
          ),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('حفظ نسخة احتياطية على الهاتف'),
            subtitle: const Text('إنشاء ملف JSON ومشاركته أو حفظه في مكان تختاره.'),
            onTap: _backup,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('استعادة نسخة احتياطية'),
            subtitle: const Text('استعادة السجل من ملف JSON محفوظ سابقًا.'),
            onTap: _restore,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('إعدادات سجلات القصر والآيات'),
            subtitle: const Text('اختيار السجلات الإضافية التي تريد إظهارها.'),
            onTap: _configureExtraTypes,
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('أعداد صلاة القصر والآيات'),
            subtitle: const Text('تحديد إجمالي القضاء لكل سجل إضافي.'),
            onTap: _configureExtraTotals,
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('تذكير يومي بقضاء الصلاة'),
            subtitle: Text(reminderEnabled ? 'موعد التذكير: ${_arabicDigits(hour)}:${_arabicDigits(minute)}' : 'غير مفعل'),
            value: reminderEnabled,
            onChanged: (value) async {
              if (value) {
                await _configureReminder();
              } else {
                await _disableReminder();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('مسح السجل بالكامل', style: TextStyle(color: Colors.red)),
            onTap: _resetAll,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool dark) {
    if (!_showStats) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.bar_chart),
          title: const Text('الإحصائيات'),
          subtitle: const Text('عرض ملخص الإنجاز وعدد الأيام المكتملة.'),
          trailing: const Icon(Icons.expand_more),
          onTap: () => setState(() => _showStats = true),
        ),
      );
    }

    final completedDays = List<int>.generate(_intValue('days', 30), (i) => i)
        .where((day) => _prayers.every((p) => _isChecked(day, p.key)))
        .length;
    final bestPrayer = _prayers.reduce((a, b) => _completedFor(a.key) >= _completedFor(b.key) ? a : b);

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('إحصائيات السجل', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(onPressed: () => setState(() => _showStats = false), icon: const Icon(Icons.expand_less)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                _statLine('مجموع الصلوات المنجزة', _arabicNumber(_completedTotal)),
                _statLine('الأيام المكتملة بالكامل', _arabicNumber(completedDays)),
                _statLine('أكثر صلاة تم قضاؤها', '${bestPrayer.name} (${_arabicNumber(_completedFor(bestPrayer.key))})'),
                _statLine('آخر إنجاز', _lastAchievementText()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _lastAchievementText() {
    for (var day = _intValue('days', 30) - 1; day >= 0; day--) {
      if (_prayers.any((p) => _isChecked(day, p.key))) return 'اليوم ${_arabicNumber(day + 1)}';
    }
    return 'لا يوجد بعد';
  }

  Widget _statLine(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PrayerInfo {
  final String key;
  final String name;
  final IconData icon;
  const _PrayerInfo(this.key, this.name, this.icon);
}
