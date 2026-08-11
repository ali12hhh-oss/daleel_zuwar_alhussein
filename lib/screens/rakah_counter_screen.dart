import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../theme.dart';

/// الصلوات الخمس.
enum PrayerName {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha,
}

extension PrayerNameX on PrayerName {
  String get arabicName {
    switch (this) {
      case PrayerName.fajr:
        return 'الفجر';
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

  /// عدد الركعات في الحالة العادية.
  int get normalRakahs {
    switch (this) {
      case PrayerName.fajr:
        return 2;
      case PrayerName.maghrib:
        return 3;
      default:
        return 4;
    }
  }

  /// صلاة المسافر:
  /// الفجر = 2
  /// المغرب = 3
  /// الظهر/العصر/العشاء = 2
  int get travelerRakahs {
    switch (this) {
      case PrayerName.fajr:
        return 2;
      case PrayerName.maghrib:
        return 3;
      default:
        return 2;
    }
  }

  String get storageKey => name;
}

/// تحويل الأرقام إلى أرقام عربية هندية.
String toArabicDigits(int n) {
  const arabic = [
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  return n
      .toString()
      .split('')
      .map((d) {
        final i = int.tryParse(d);
        return i == null ? d : arabic[i];
      })
      .join();
}

class RakahCounterScreen extends StatefulWidget {
  /// أوقات الصلاة المحسوبة مسبقًا من شاشة مواقيت الصلاة.
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
  // ---------------------------------------------------------------------------
  // مفاتيح التخزين
  // ---------------------------------------------------------------------------

  static const _kDateKey = 'rakah_counter_date';
  static const _kSujudKey = 'rakah_counter_sujud';
  static const _kRakahKey = 'rakah_counter_rakah';
  static const _kPrayerKey = 'rakah_counter_prayer';
  static const _kManualKey = 'rakah_counter_manual_mode';

  static const _kDhuhrDoneKey = 'rakah_counter_dhuhr_done_date';
  static const _kMaghribDoneKey = 'rakah_counter_maghrib_done_date';

  static const _kTravelerKey = 'rakah_counter_traveler';

  static const _kVibrationKey = 'rakah_counter_vibration';
  static const _kInputModeKey = 'rakah_counter_input_mode';
  static const _kUiScaleKey = 'rakah_counter_ui_scale';

  static const _kCompletedPrayerPrefix = 'rakah_counter_completed_';

  // ---------------------------------------------------------------------------
  // حالة العد
  // ---------------------------------------------------------------------------

  int _sujudCount = 0;
  int _rakahCount = 0;

  bool _manualMode = false;
  PrayerName? _manualPrayer;

  String? _dhuhrDoneDate;
  String? _maghribDoneDate;

  bool _isTraveler = false;
  bool _vibrationEnabled = true;

  /// touch = لمس الشاشة
  /// buttons = أزرار
  String _inputMode = 'touch';

  /// 0.90 / 1.0 / 1.12
  double _uiScale = 1.0;

  String? _reminderMessage;

  bool _hasVibrator = true;

  /// الصلوات المكتملة لهذا اليوم.
  final Set<PrayerName> _completedPrayers = {};

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _glowController;

  Timer? _reminderTimer;

  // ---------------------------------------------------------------------------
  // دورة الحياة
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0,
      upperBound: 1,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).chain(
      CurveTween(curve: Curves.easeOut),
    ).animate(_pulseController);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _init();
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // التاريخ
  // ---------------------------------------------------------------------------

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  // ---------------------------------------------------------------------------
  // عدد الركعات الحالي
  // ---------------------------------------------------------------------------

  int _totalRakahsFor(PrayerName prayer) {
    return _isTraveler
        ? prayer.travelerRakahs
        : prayer.normalRakahs;
  }

  // ---------------------------------------------------------------------------
  // التهيئة
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    _hasVibrator = await Vibration.hasVibrator() ?? false;

    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString(_kDateKey);

    _dhuhrDoneDate = prefs.getString(_kDhuhrDoneKey);
    _maghribDoneDate = prefs.getString(_kMaghribDoneKey);

    _manualMode = prefs.getBool(_kManualKey) ?? false;
    _isTraveler = prefs.getBool(_kTravelerKey) ?? false;
    _vibrationEnabled = prefs.getBool(_kVibrationKey) ?? true;

    _inputMode = prefs.getString(_kInputModeKey) ?? 'touch';

    _uiScale = prefs.getDouble(_kUiScaleKey) ?? 1.0;

    final savedPrayer = prefs.getString(_kPrayerKey);

    if (savedPrayer != null) {
      _manualPrayer = PrayerName.values.firstWhere(
        (p) => p.storageKey == savedPrayer,
        orElse: () => PrayerName.fajr,
      );
    }

    if (savedDate == _today) {
      _sujudCount = prefs.getInt(_kSujudKey) ?? 0;
      _rakahCount = prefs.getInt(_kRakahKey) ?? 0;

      for (final prayer in PrayerName.values) {
        if (prefs.getBool(_completedKey(prayer)) ?? false) {
          _completedPrayers.add(prayer);
        }
      }
    } else {
      _sujudCount = 0;
      _rakahCount = 0;
      _completedPrayers.clear();
    }

    if (mounted) {
      setState(() {});
    }
  }

  String _completedKey(PrayerName prayer) {
    return '$_kCompletedPrayerPrefix${prayer.storageKey}_$_today';
  }

  // ---------------------------------------------------------------------------
  // الحفظ
  // ---------------------------------------------------------------------------

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_kDateKey, _today);
    await prefs.setInt(_kSujudKey, _sujudCount);
    await prefs.setInt(_kRakahKey, _rakahCount);

    await prefs.setBool(_kManualKey, _manualMode);
    await prefs.setBool(_kTravelerKey, _isTraveler);
    await prefs.setBool(_kVibrationKey, _vibrationEnabled);

    await prefs.setString(_kInputModeKey, _inputMode);
    await prefs.setDouble(_kUiScaleKey, _uiScale);

    if (_manualPrayer != null) {
      await prefs.setString(
        _kPrayerKey,
        _manualPrayer!.storageKey,
      );
    } else {
      await prefs.remove(_kPrayerKey);
    }

    if (_dhuhrDoneDate != null) {
      await prefs.setString(_kDhuhrDoneKey, _dhuhrDoneDate!);
    }

    if (_maghribDoneDate != null) {
      await prefs.setString(
        _kMaghribDoneKey,
        _maghribDoneDate!,
      );
    }

    for (final prayer in PrayerName.values) {
      await prefs.setBool(
        _completedKey(prayer),
        _completedPrayers.contains(prayer),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // التحديد التلقائي
  // ---------------------------------------------------------------------------

  PrayerName? get _autoPrayer {
    final now = DateTime.now();

    final fajr = widget.fajrAdhan;
    final sunrise = widget.sunrise;
    final dhuhr = widget.dhuhrAdhan;
    final maghrib = widget.maghribAdhan;
    final midnight = widget.midnight;

    if (fajr != null &&
        sunrise != null &&
        now.isAfter(fajr) &&
        now.isBefore(sunrise)) {
      return PrayerName.fajr;
    }

    if (dhuhr != null &&
        maghrib != null &&
        now.isAfter(dhuhr) &&
        now.isBefore(maghrib)) {
      return _dhuhrDoneDate == _today
          ? PrayerName.asr
          : PrayerName.dhuhr;
    }

    if (maghrib != null &&
        midnight != null &&
        now.isAfter(maghrib) &&
        now.isBefore(midnight)) {
      return _maghribDoneDate == _today
          ? PrayerName.isha
          : PrayerName.maghrib;
    }

    return null;
  }

  PrayerName? get _activePrayer {
    if (_manualMode) {
      return _manualPrayer ?? _autoPrayer;
    }

    return _autoPrayer ?? _manualPrayer;
  }

  // ---------------------------------------------------------------------------
  // الصوت والاهتزاز
  // ---------------------------------------------------------------------------

  Future<void> _feedback({bool strong = false}) async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}

    if (!_vibrationEnabled || !_hasVibrator) {
      return;
    }

    try {
      if (strong) {
        await Vibration.vibrate(
          pattern: [0, 120, 80, 120],
        );
      } else {
        await Vibration.vibrate(
          duration: 40,
        );
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // رسالة داخلية
  // ---------------------------------------------------------------------------

  void _showReminder(String message) {
    _reminderTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _reminderMessage = message;
    });

    _reminderTimer = Timer(
      const Duration(seconds: 4),
      () {
        if (!mounted) return;

        setState(() {
          _reminderMessage = null;
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // الضغط
  // ---------------------------------------------------------------------------

  Future<void> _onTap() async {
    final prayer = _activePrayer;

    if (prayer == null) {
      return;
    }

    await _pulseController.forward();
    await _pulseController.reverse();

    await _feedback();

    if (!mounted) return;

    setState(() {
      _sujudCount++;
    });

    // السجدة الثانية = اكتمال الركعة.
    if (_sujudCount >= 2) {
      setState(() {
        _sujudCount = 0;
        _rakahCount++;
      });

      await _feedback(strong: true);

      final total = _totalRakahsFor(prayer);

      // إكمال الصلاة.
      if (_rakahCount >= total) {
        await _completePrayer(prayer);
        return;
      }

      // التشهد بعد الركعة الثانية.
      if (_rakahCount == 2 && total > 2) {
        _showReminder('التشهد');
      }
    }

    await _persist();
  }

  // ---------------------------------------------------------------------------
  // إكمال الصلاة
  // ---------------------------------------------------------------------------

  Future<void> _completePrayer(PrayerName prayer) async {
    _showReminder(
      'التشهد والتسليم — تقبل الله صلاتك 🤍',
    );

    await _persist();

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    setState(() {
      _completedPrayers.add(prayer);

      if (prayer == PrayerName.dhuhr) {
        _dhuhrDoneDate = _today;
      }

      if (prayer == PrayerName.maghrib) {
        _maghribDoneDate = _today;
      }

      _sujudCount = 0;
      _rakahCount = 0;
    });

    await _persist();

    _showReminder(
      'تم تسجيل صلاة ${prayer.arabicName} في سجل اليوم ✓',
    );
  }

  // ---------------------------------------------------------------------------
  // تصفير العد
  // ---------------------------------------------------------------------------

  Future<void> _resetCount({
    bool markDoneForTransition = false,
  }) async {
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

    _showReminder('تم تصفير عداد الصلاة');
  }

  // ---------------------------------------------------------------------------
  // اختيار الفريضة يدويًا
  // ---------------------------------------------------------------------------

  void _openManualPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _ManualPrayerSheet(
          current: _activePrayer,
          onSelect: (prayer) async {
            setState(() {
              _manualMode = true;
              _manualPrayer = prayer;
              _sujudCount = 0;
              _rakahCount = 0;
            });

            await _persist();

            if (mounted) {
              Navigator.pop(ctx);
            }

            _showReminder(
              'تم اختيار صلاة ${prayer.arabicName} يدويًا',
            );
          },
          onAuto: () async {
            setState(() {
              _manualMode = false;
              _manualPrayer = null;
              _sujudCount = 0;
              _rakahCount = 0;
            });

            await _persist();

            if (mounted) {
              Navigator.pop(ctx);
            }

            _showReminder(
              'عاد التحديد التلقائي حسب وقت الصلاة',
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // الإعدادات
  // ---------------------------------------------------------------------------

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _SettingsSheet(
          traveler: _isTraveler,
          vibrationEnabled: _vibrationEnabled,
          inputMode: _inputMode,
          uiScale: _uiScale,
          onTravelerChanged: (value) async {
            if (!mounted) return;

            setState(() {
              _isTraveler = value;
              _sujudCount = 0;
              _rakahCount = 0;
            });

            await _persist();
          },
          onVibrationChanged: (value) async {
            if (!mounted) return;

            setState(() {
              _vibrationEnabled = value;
            });

            await _persist();
          },
          onInputModeChanged: (value) async {
            if (!mounted) return;

            setState(() {
              _inputMode = value;
            });

            await _persist();
          },
          onScaleChanged: (value) async {
            if (!mounted) return;

            setState(() {
              _uiScale = value;
            });

            await _persist();
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // سجل اليوم
  // ---------------------------------------------------------------------------

  void _openDailyRecord() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _DailyRecordSheet(
          completed: _completedPrayers,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // البناء
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final prayer = _activePrayer;

    final total = prayer == null
        ? 0
        : _totalRakahsFor(prayer);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF071D17),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'عداد الركعات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'سجل اليوم',
              icon: const Icon(
                Icons.history_rounded,
              ),
              onPressed: _openDailyRecord,
            ),
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(
                Icons.tune_rounded,
              ),
              onPressed: _openSettings,
            ),
            IconButton(
              tooltip: 'اختيار الفريضة يدويًا',
              icon: const Icon(
                Icons.mosque_rounded,
              ),
              onPressed: _openManualPicker,
            ),
          ],
        ),
        body: SafeArea(
          child: prayer == null
              ? _buildNoActivePrayer()
              : _buildPrayerBody(
                  prayer,
                  total,
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // الشاشة الرئيسية
  // ---------------------------------------------------------------------------

  Widget _buildPrayerBody(
    PrayerName prayer,
    int total,
  ) {
    final content = Column(
      children: [
        const SizedBox(height: 8),

        _buildHeader(prayer),

        const SizedBox(height: 20),

        _buildSujudSection(),

        Expanded(
          child: Center(
            child: _buildCounter(total),
          ),
        ),

        _buildRakahSection(total),

        const SizedBox(height: 14),

        _buildInputControl(),

        const SizedBox(height: 10),

        _buildHint(),

        const SizedBox(height: 18),
      ],
    );

    if (_inputMode == 'touch') {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: content,
      );
    }

    return content;
  }

  // ---------------------------------------------------------------------------
  // لا توجد صلاة حالية
  // ---------------------------------------------------------------------------

  Widget _buildNoActivePrayer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIconContainer(
              Icons.self_improvement_rounded,
              size: 84,
            ),

            const SizedBox(height: 20),

            const Text(
              'لا توجد فريضة حالية ضمن الأوقات المحسوبة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 9),

            const Text(
              'يمكنك اختيار الفريضة يدويًا من الزر أعلى الشاشة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: _openManualPicker,
              icon: const Icon(
                Icons.mosque_rounded,
              ),
              label: const Text(
                'اختيار الفريضة',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lightGold,
                foregroundColor: const Color(0xFF082219),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // رأس الصلاة
  // ---------------------------------------------------------------------------

  Widget _buildHeader(
    PrayerName prayer,
  ) {
    return Column(
      children: [
        Text(
          'صلاة ${prayer.arabicName}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 5),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _manualMode
                  ? Icons.touch_app_rounded
                  : Icons.access_time_rounded,
              size: 14,
              color: AppColors.lightGold,
            ),
            const SizedBox(width: 5),
            Text(
              _manualMode
                  ? 'اختيار يدوي'
                  : 'تلقائي حسب وقت الصلاة',
              style: const TextStyle(
                color: AppColors.lightGold,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        if (_isTraveler)
          _buildSmallBadge(
            'وضع المسافر • ${toArabicDigits(_totalRakahsFor(prayer))} ركعات',
          ),

        if (_reminderMessage != null) ...[
          const SizedBox(height: 12),
          _buildReminder(),
        ],
      ],
    );
  }

  Widget _buildReminder() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(_reminderMessage),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.lightGold.withOpacity(0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.lightGold.withOpacity(0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightGold.withOpacity(0.08),
              blurRadius: 16,
            ),
          ],
        ),
        child: Text(
          _reminderMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.lightGold,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // قسم السجدات
  // ---------------------------------------------------------------------------

  Widget _buildSujudSection() {
    return Column(
      children: [
        const Text(
          'عدد السجدات',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            2,
            (index) {
              final number = index + 1;
              final selected = number <= _sujudCount;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(
                  horizontal: 6,
                ),
                width: 45 * _uiScale,
                height: 45 * _uiScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.lightGold.withOpacity(1),
                            AppColors.lightGold.withOpacity(0.60),
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF183E32),
                            Color(0xFF0B2B22),
                          ],
                        ),
                  border: Border.all(
                    color: selected
                        ? AppColors.lightGold
                        : Colors.white24,
                    width: 1.4,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.lightGold.withOpacity(0.30),
                            blurRadius: 18,
                            spreadRadius: -2,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    toArabicDigits(number),
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF09251B)
                          : Colors.white70,
                      fontSize: 20 * _uiScale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // العداد الرئيسي
  // ---------------------------------------------------------------------------

  Widget _buildCounter(
    int total,
  ) {
    final diameter = 230 * _uiScale;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _glowController,
      ]),
      builder: (context, child) {
        final glow = 0.18 + (_glowController.value * 0.08);

        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.35, -0.40),
                radius: 0.90,
                colors: [
                  Color(0xFF26765A),
                  Color(0xFF15503E),
                  Color(0xFF0A2B22),
                ],
              ),
              border: Border.all(
                color: AppColors.lightGold.withOpacity(0.60),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.55),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: AppColors.lightGold.withOpacity(glow),
                  blurRadius: 35,
                  spreadRadius: -7,
                ),
                const BoxShadow(
                  color: Colors.white12,
                  blurRadius: 10,
                  offset: Offset(-7, -7),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 24,
                  left: 35,
                  right: 70,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'عدد الركعات',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13 * _uiScale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        toArabicDigits(_rakahCount),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 72 * _uiScale,
                          height: 0.95,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 7),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white12,
                          ),
                        ),
                        child: Text(
                          'من ${toArabicDigits(total)}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13 * _uiScale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // الركعات
  // ---------------------------------------------------------------------------

  Widget _buildRakahSection(
    int total,
  ) {
    return Column(
      children: [
        Text(
          'الركعات',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12 * _uiScale,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 9),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            total,
            (index) {
              final selected = index < _rakahCount;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                width: 22 * _uiScale,
                height: 22 * _uiScale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.lightGold
                      : Colors.white10,
                  border: Border.all(
                    color: selected
                        ? AppColors.lightGold
                        : Colors.white24,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.lightGold.withOpacity(0.30),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // طريقة العد
  // ---------------------------------------------------------------------------

  Widget _buildInputControl() {
    if (_inputMode == 'touch') {
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 24,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.touch_app_rounded,
              color: Colors.white54,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'المس الشاشة عند كل سجدة',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 62 * _uiScale,
        child: ElevatedButton(
          onPressed: _onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.lightGold,
            foregroundColor: const Color(0xFF09251B),
            elevation: 10,
            shadowColor: AppColors.lightGold.withOpacity(0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 22 * _uiScale,
              ),
              const SizedBox(width: 9),
              Text(
                'سجدة',
                style: TextStyle(
                  fontSize: 18 * _uiScale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // تلميح
  // ---------------------------------------------------------------------------

  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Text(
        _inputMode == 'touch'
            ? 'ضع الجهاز بالقرب منك والمس الشاشة عند كل سجدة.'
            : 'اضغط زر "سجدة" مرة واحدة عند كل سجدة.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white38,
          fontSize: 11.5 * _uiScale,
          height: 1.5,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // عناصر تصميم
  // ---------------------------------------------------------------------------

  Widget _buildSmallBadge(
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightGold.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppColors.lightGold.withOpacity(0.30),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.lightGold,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildIconContainer(
    IconData icon, {
    double size = 70,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF246C53),
            Color(0xFF0D3025),
          ],
        ),
        border: Border.all(
          color: AppColors.lightGold.withOpacity(0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightGold.withOpacity(0.12),
            blurRadius: 25,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: AppColors.lightGold,
        size: size * 0.48,
      ),
    );
  }
}

// =============================================================================
// اختيار الفريضة
// =============================================================================

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
          color: Color(0xFF0D3025),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'اختر الفريضة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 17),

            Wrap(
              spacing: 9,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: PrayerName.values.map(
                (p) {
                  final selected = p == current;

                  return ChoiceChip(
                    label: Text(
                      p.arabicName,
                    ),
                    selected: selected,
                    onSelected: (_) => onSelect(p),
                    backgroundColor: Colors.white10,
                    selectedColor: AppColors.lightGold,
                    labelStyle: TextStyle(
                      color: selected
                          ? const Color(0xFF09251B)
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: selected
                            ? AppColors.lightGold
                            : Colors.white12,
                      ),
                    ),
                  );
                },
              ).toList(),
            ),

            const SizedBox(height: 17),

            TextButton.icon(
              onPressed: onAuto,
              icon: const Icon(
                Icons.autorenew_rounded,
                color: AppColors.lightGold,
              ),
              label: const Text(
                'رجوع للتحديد التلقائي حسب الوقت',
                style: TextStyle(
                  color: AppColors.lightGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// الإعدادات — تم تعديلها لتتحدث فورًا داخل النافذة
// =============================================================================

class _SettingsSheet extends StatefulWidget {
  final bool traveler;
  final bool vibrationEnabled;
  final String inputMode;
  final double uiScale;

  final ValueChanged<bool> onTravelerChanged;
  final ValueChanged<bool> onVibrationChanged;
  final ValueChanged<String> onInputModeChanged;
  final ValueChanged<double> onScaleChanged;

  const _SettingsSheet({
    required this.traveler,
    required this.vibrationEnabled,
    required this.inputMode,
    required this.uiScale,
    required this.onTravelerChanged,
    required this.onVibrationChanged,
    required this.onInputModeChanged,
    required this.onScaleChanged,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late bool _traveler;
  late bool _vibrationEnabled;
  late String _inputMode;
  late double _uiScale;

  @override
  void initState() {
    super.initState();

    _traveler = widget.traveler;
    _vibrationEnabled = widget.vibrationEnabled;
    _inputMode = widget.inputMode;
    _uiScale = widget.uiScale;
  }

  // ---------------------------------------------------------------------------
  // تغيير وضع المسافر
  // ---------------------------------------------------------------------------

  Future<void> _changeTraveler(bool value) async {
    // تحديث الواجهة فورًا.
    if (mounted) {
      setState(() {
        _traveler = value;
      });
    }

    // ثم حفظ القيمة في الشاشة الرئيسية والتخزين.
    widget.onTravelerChanged(value);
  }

  // ---------------------------------------------------------------------------
  // تغيير الاهتزاز
  // ---------------------------------------------------------------------------

  Future<void> _changeVibration(bool value) async {
    // تحديث الزر فورًا.
    if (mounted) {
      setState(() {
        _vibrationEnabled = value;
      });
    }

    widget.onVibrationChanged(value);
  }

  // ---------------------------------------------------------------------------
  // تغيير طريقة العد
  // ---------------------------------------------------------------------------

  Future<void> _changeInputMode(String value) async {
    // تحديث الاختيار فورًا.
    if (mounted) {
      setState(() {
        _inputMode = value;
      });
    }

    widget.onInputModeChanged(value);
  }

  // ---------------------------------------------------------------------------
  // تغيير حجم الواجهة
  // ---------------------------------------------------------------------------

  Future<void> _changeScale(double value) async {
    // تحديث الزر فورًا.
    if (mounted) {
      setState(() {
        _uiScale = value;
      });
    }

    widget.onScaleChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D3025),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          28,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // المقبض العلوي
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'إعدادات العدّاد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 18),

                // =============================================================
                // نوع الصلاة
                // =============================================================

                _sectionTitle('نوع الصلاة'),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'وضع المسافر',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'الظهر والعصر والعشاء ركعتان',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  value: _traveler,
                  activeColor: AppColors.lightGold,
                  onChanged: _changeTraveler,
                ),

                const SizedBox(height: 12),

                // =============================================================
                // طريقة العد
                // =============================================================

                _sectionTitle('طريقة العد'),

                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'touch',
                  groupValue: _inputMode,
                  activeColor: AppColors.lightGold,
                  title: const Text(
                    'لمس الشاشة',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  secondary: const Icon(
                    Icons.touch_app_rounded,
                    color: Colors.white54,
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      _changeInputMode(value);
                    }
                  },
                ),

                RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  value: 'buttons',
                  groupValue: _inputMode,
                  activeColor: AppColors.lightGold,
                  title: const Text(
                    'زر على الشاشة',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  secondary: const Icon(
                    Icons.smart_button_rounded,
                    color: Colors.white54,
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      _changeInputMode(value);
                    }
                  },
                ),

                const SizedBox(height: 12),

                // =============================================================
                // الصوت والاهتزاز
                // =============================================================

                _sectionTitle('الصوت والاهتزاز'),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'الاهتزاز',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    'اهتزاز خفيف لكل سجدة وأقوى عند اكتمال الركعة',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  value: _vibrationEnabled,
                  activeColor: AppColors.lightGold,
                  onChanged: _changeVibration,
                ),

                const SizedBox(height: 12),

                // =============================================================
                // حجم الواجهة
                // =============================================================

                _sectionTitle('حجم الواجهة'),

                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<double>(
                    segments: const [
                      ButtonSegment<double>(
                        value: 0.90,
                        label: Text('صغير'),
                      ),
                      ButtonSegment<double>(
                        value: 1.0,
                        label: Text('متوسط'),
                      ),
                      ButtonSegment<double>(
                        value: 1.12,
                        label: Text('كبير'),
                      ),
                    ],
                    selected: <double>{_uiScale},
                    onSelectionChanged: (selection) {
                      if (selection.isNotEmpty) {
                        _changeScale(
                          selection.first,
                        );
                      }
                    },
                    style: ButtonStyle(
                      foregroundColor:
                          MaterialStateProperty.resolveWith<Color?>(
                        (states) {
                          if (states.contains(
                            MaterialState.selected,
                          )) {
                            return const Color(0xFF09251B);
                          }

                          return Colors.white70;
                        },
                      ),
                      backgroundColor:
                          MaterialStateProperty.resolveWith<Color?>(
                        (states) {
                          if (states.contains(
                            MaterialState.selected,
                          )) {
                            return AppColors.lightGold;
                          }

                          return Colors.white10;
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.lightGold,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// =============================================================================
// سجل اليوم
// =============================================================================

class _DailyRecordSheet extends StatelessWidget {
  final Set<PrayerName> completed;

  const _DailyRecordSheet({
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final count = completed.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D3025),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          28,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                'سجل اليوم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '${toArabicDigits(count)} من ${toArabicDigits(5)} صلوات مكتملة',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 18),

              ...PrayerName.values.map(
                (prayer) {
                  final isDone = completed.contains(prayer);

                  return Container(
                    margin: const EdgeInsets.only(
                      bottom: 9,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDone
                          ? AppColors.lightGold.withOpacity(0.08)
                          : Colors.white.withOpacity(0.035),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDone
                            ? AppColors.lightGold.withOpacity(0.30)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isDone
                              ? AppColors.lightGold
                              : Colors.white30,
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            prayer.arabicName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        Text(
                          isDone ? 'مكتملة' : 'غير مكتملة',
                          style: TextStyle(
                            color: isDone
                                ? AppColors.lightGold
                                : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
