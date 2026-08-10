import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../theme.dart';

/// الصلوات الخمس التي يدعمها العدّاد.
enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

extension PrayerNameX on PrayerName {
  String get arabicName {
    switch (this) {
      case PrayerName.fajr:
        return 'الصبح';
      case PrayerName.dhuhr:
        return 'الظهر';
      case PrayerName.asr:
        return 'العصر';
      case PrayerName.maghrib:
        return 'المغرب';
      case PrayerName.isha:
        return 'العشاء';
    }
  }

  /// عدد الركعات الكامل لكل فريضة (لغير المسافر).
  int get totalRakahs {
    switch (this) {
      case PrayerName.fajr:
        return 2;
      case PrayerName.maghrib:
        return 3;
      default:
        return 4;
    }
  }

  String get storageKey => name;
}

/// يحوّل رقماً صحيحاً إلى أرقام عربية-هندية (١٢٣) للعرض.
String toArabicDigits(int n) {
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((d) {
    final i = int.tryParse(d);
    return i == null ? d : arabic[i];
  }).join();
}

class RakahCounterScreen extends StatefulWidget {
  /// أوقات الصلاة المحسوبة مسبقاً (نفس مصدر شاشة مواقيت الصلاة)، تُستخدم
  /// لتحديد الفريضة الحالية تلقائياً. أي قيمة فارغة تعطّل التحديد
  /// التلقائي وتبقي الاختيار اليدوي فقط متاحاً.
  final DateTime? fajrAdhan;
  final DateTime? sunrise;
  final DateTime? dhuhrAdhan;
  final DateTime? maghribAdhan;
  final DateTime? midnight;

  const RakahCounterScreen({
    super.key,
    this.fajrAdhan,
    this.sunrise,
    this.dhuhrAdhan,
    this.maghribAdhan,
    this.midnight,
  });

  @override
  State<RakahCounterScreen> createState() => _RakahCounterScreenState();
}

class _RakahCounterScreenState extends State<RakahCounterScreen>
    with SingleTickerProviderStateMixin {
  static const _kDateKey = 'rakah_counter_date';
  static const _kSujudKey = 'rakah_counter_sujud';
  static const _kRakahKey = 'rakah_counter_rakah';
  static const _kPrayerKey = 'rakah_counter_prayer';
  static const _kManualKey = 'rakah_counter_manual_mode';
  static const _kDhuhrDoneKey = 'rakah_counter_dhuhr_done_date';
  static const _kMaghribDoneKey = 'rakah_counter_maghrib_done_date';

  int _sujudCount = 0; // 0 أو 1، يصفَّر كل سجدتين
  int _rakahCount = 0;
  bool _manualMode = false;
  PrayerName? _manualPrayer;
  String? _dhuhrDoneDate;
  String? _maghribDoneDate;
  String? _reminderMessage;
  bool _hasVibrator = true;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.92)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_pulseController);
    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _init() async {
    _hasVibrator = await Vibration.hasVibrator() ?? false;
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_kDateKey);
    _dhuhrDoneDate = prefs.getString(_kDhuhrDoneKey);
    _maghribDoneDate = prefs.getString(_kMaghribDoneKey);
    _manualMode = prefs.getBool(_kManualKey) ?? false;
    final savedPrayer = prefs.getString(_kPrayerKey);
    if (savedPrayer != null) {
      _manualPrayer = PrayerName.values.firstWhere(
        (p) => p.storageKey == savedPrayer,
        orElse: () => PrayerName.fajr,
      );
    }
    // يُستأنف العدّ من نفس اليوم فقط، وإلا يبدأ من جديد.
    if (savedDate == _today) {
      _sujudCount = prefs.getInt(_kSujudKey) ?? 0;
      _rakahCount = prefs.getInt(_kRakahKey) ?? 0;
    }
    if (mounted) setState(() {});
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDateKey, _today);
    await prefs.setInt(_kSujudKey, _sujudCount);
    await prefs.setInt(_kRakahKey, _rakahCount);
    await prefs.setBool(_kManualKey, _manualMode);
    if (_manualPrayer != null) {
      await prefs.setString(_kPrayerKey, _manualPrayer!.storageKey);
    }
    if (_dhuhrDoneDate != null) {
      await prefs.setString(_kDhuhrDoneKey, _dhuhrDoneDate!);
    }
    if (_maghribDoneDate != null) {
      await prefs.setString(_kMaghribDoneKey, _maghribDoneDate!);
    }
  }

  /// يحدّد الفريضة الحالية تلقائياً حسب الوقت الفعلي، أو يرجع null إذا
  /// كنا خارج أي نافذة صلاة معروفة (بين الشروق والزوال مثلاً).
  PrayerName? get _autoPrayer {
    final now = DateTime.now();
    final fajr = widget.fajrAdhan;
    final sunrise = widget.sunrise;
    final dhuhr = widget.dhuhrAdhan;
    final maghrib = widget.maghribAdhan;
    final midnight = widget.midnight;

    if (fajr != null && sunrise != null &&
        now.isAfter(fajr) && now.isBefore(sunrise)) {
      return PrayerName.fajr;
    }
    if (dhuhr != null && maghrib != null &&
        now.isAfter(dhuhr) && now.isBefore(maghrib)) {
      return _dhuhrDoneDate == _today ? PrayerName.asr : PrayerName.dhuhr;
    }
    if (maghrib != null && midnight != null &&
        now.isAfter(maghrib) && now.isBefore(midnight)) {
      return _maghribDoneDate == _today ? PrayerName.isha : PrayerName.maghrib;
    }
    return null;
  }

  PrayerName? get _activePrayer =>
      _manualMode ? (_manualPrayer ?? _autoPrayer) : (_autoPrayer ?? _manualPrayer);

  Future<void> _feedback({bool strong = false}) async {
    SystemSound.play(SystemSoundType.click);
    if (_hasVibrator) {
      if (strong) {
        Vibration.vibrate(pattern: [0, 120, 80, 120]);
      } else {
        Vibration.vibrate(duration: 40);
      }
    }
  }

  void _showReminder(String message) {
    setState(() => _reminderMessage = message);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _reminderMessage = null);
    });
  }

  Future<void> _resetCount({bool markDoneForTransition = false}) async {
    final prayer = _activePrayer;
    setState(() {
      _sujudCount = 0;
      _rakahCount = 0;
      if (markDoneForTransition && prayer == PrayerName.dhuhr) {
        _dhuhrDoneDate = _today;
      }
      if (markDoneForTransition && prayer == PrayerName.maghrib) {
        _maghribDoneDate = _today;
      }
    });
    await _persist();
  }

  Future<void> _onTap() async {
    final prayer = _activePrayer;
    if (prayer == null) return;

    _pulseController.forward().then((_) => _pulseController.reverse());
    await _feedback();

    setState(() => _sujudCount++);

    if (_sujudCount >= 2) {
      _sujudCount = 0;
      _rakahCount++;
      await _feedback(strong: true);

      final total = prayer.totalRakahs;
      if (_rakahCount == total) {
        // آخر ركعة: تشهد + تسليم، وإنهاء الصلاة
        _showReminder('التشهد والتسليم — أتمّ الله صلاتك 🤍');
        await _persist();
        await Future.delayed(const Duration(milliseconds: 300));
        await _resetCount(markDoneForTransition: true);
        return;
      } else if (_rakahCount == 2) {
        _showReminder('التشهد');
      }
    }
    await _persist();
  }

  void _openManualPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ManualPrayerSheet(
        current: _activePrayer,
        onSelect: (prayer) async {
          setState(() {
            _manualMode = true;
            _manualPrayer = prayer;
            _sujudCount = 0;
            _rakahCount = 0;
          });
          await _persist();
          if (mounted) Navigator.pop(ctx);
        },
        onAuto: () async {
          setState(() {
            _manualMode = false;
            _manualPrayer = null;
            _sujudCount = 0;
            _rakahCount = 0;
          });
          await _persist();
          if (mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayer = _activePrayer;
    final total = prayer?.totalRakahs ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B2A21),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('عداد الركعات'),
          actions: [
            IconButton(
              tooltip: 'اختيار الفريضة يدوياً',
              icon: const Icon(Icons.tune),
              onPressed: _openManualPicker,
            ),
            IconButton(
              tooltip: 'تصفير العدّاد',
              icon: const Icon(Icons.refresh),
              onPressed: prayer == null ? null : () => _resetCount(),
            ),
          ],
        ),
        body: SafeArea(
          child: prayer == null
              ? _buildNoActivePrayer()
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _onTap,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader(prayer),
                      const SizedBox(height: 12),
                      _buildSujudDots(),
                      Expanded(child: Center(child: _buildCounter(total))),
                      _buildRakahDots(total),
                      const SizedBox(height: 16),
                      _buildHint(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNoActivePrayer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.self_improvement, size: 64, color: AppColors.lightGold),
            const SizedBox(height: 16),
            const Text(
              'لا توجد فريضة حالية ضمن الأوقات المحسوبة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'يمكنك اختيار الفريضة يدوياً من الزر أعلى الشاشة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openManualPicker,
              icon: const Icon(Icons.tune),
              label: const Text('اختيار الفريضة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightGold,
                foregroundColor: const Color(0xFF0B2A21),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PrayerName prayer) {
    return Column(
      children: [
        Text(
          'صلاة ${prayer.arabicName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _manualMode ? 'اختيار يدوي' : 'تلقائي حسب وقت الصلاة',
          style: const TextStyle(color: AppColors.lightGold, fontSize: 12),
        ),
        if (_reminderMessage != null) ...[
          const SizedBox(height: 10),
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightGold, width: 1),
              ),
              child: Text(
                _reminderMessage!,
                style: const TextStyle(color: AppColors.lightGold, fontSize: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSujudDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final filled = i < _sujudCount;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppColors.lightGold : Colors.white24,
          ),
        );
      }),
    );
  }

  Widget _buildCounter(int total) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: child,
      ),
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF1C5A45), Color(0xFF0F3D2F)],
            center: Alignment(-0.3, -0.3),
            radius: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: AppColors.lightGold.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: -6,
            ),
            const BoxShadow(
              color: Colors.white24,
              blurRadius: 8,
              offset: Offset(-6, -6),
            ),
          ],
          border: Border.all(color: AppColors.lightGold.withOpacity(0.5), width: 2),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                toArabicDigits(_rakahCount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
              ),
              Text(
                'من ${toArabicDigits(total)}',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRakahDots(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final filled = i < _rakahCount;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? AppColors.lightGold : Colors.white12,
              border: Border.all(
                color: filled ? AppColors.lightGold : Colors.white38,
                width: 1.5,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHint() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'ضع الجهاز قرب موضع سجودك، والمس الشاشة بجبهتك عند كل سجدة',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, fontSize: 12.5, height: 1.6),
      ),
    );
  }
}

class _ManualPrayerSheet extends StatelessWidget {
  final PrayerName? current;
  final ValueChanged<PrayerName> onSelect;
  final VoidCallback onAuto;

  const _ManualPrayerSheet({
    required this.current,
    required this.onSelect,
    required this.onAuto,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F3D2F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر الفريضة',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: PrayerName.values.map((p) {
                final selected = p == current;
                return ChoiceChip(
                  label: Text(p.arabicName),
                  selected: selected,
                  onSelected: (_) => onSelect(p),
                  backgroundColor: Colors.white10,
                  selectedColor: AppColors.lightGold,
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFF0B2A21) : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onAuto,
              icon: const Icon(Icons.autorenew, color: AppColors.lightGold),
              label: const Text(
                'رجوع للتحديد التلقائي حسب الوقت',
                style: TextStyle(color: AppColors.lightGold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
