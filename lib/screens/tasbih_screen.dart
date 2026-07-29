import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../theme.dart';

enum _TasbihMode { zahra, other }

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  _TasbihMode _mode = _TasbihMode.zahra;

  int _counter = 0;
  int _target = 34;
  String _currentDhikr = 'الله أكبر';
  int _round = 1;

  // ✅ تسبيح الزهراء عليها السلام بالترتيب الشرعي: تكبير ثم تحميد ثم تسبيح
  final List<Map<String, dynamic>> _zahraAdhkar = [
    {'text': 'الله أكبر', 'target': 34, 'round': 1},
    {'text': 'الحمد لله', 'target': 33, 'round': 2},
    {'text': 'سبحان الله', 'target': 33, 'round': 3},
  ];

  // ✅ أذكار أخرى مستقلة، كل ذكر 100 مرة بشكل منفصل (لا ترتبط بتسبيح الزهراء)
  final List<Map<String, dynamic>> _otherAdhkar = [
    {'text': 'أستغفر الله', 'target': 100},
    {'text': 'لا حول ولا قوة إلا بالله', 'target': 100},
    {'text': 'سبحان الله وبحمده سبحان الله العظيم', 'target': 100},
    {'text': 'اللهم صل على محمد وآل محمد', 'target': 100},
  ];

  List<Map<String, dynamic>> get _activeList =>
      _mode == _TasbihMode.zahra ? _zahraAdhkar : _otherAdhkar;

  void _switchMode(_TasbihMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      final first = _activeListFor(mode).first;
      _currentDhikr = first['text'];
      _target = first['target'];
      _round = first['round'] ?? 1;
      _counter = 0;
    });
  }

  List<Map<String, dynamic>> _activeListFor(_TasbihMode mode) =>
      mode == _TasbihMode.zahra ? _zahraAdhkar : _otherAdhkar;

  void _increment() {
    setState(() {
      _counter++;
      if (_counter >= _target) {
        _vibrate();
        if (_mode == _TasbihMode.zahra) {
          _nextZahraDhikr();
        } else {
          _counter = 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم إكمال 100 من: $_currentDhikr')),
          );
        }
      }
    });
  }

  void _nextZahraDhikr() {
    final currentIndex =
        _zahraAdhkar.indexWhere((a) => a['text'] == _currentDhikr);
    if (currentIndex < _zahraAdhkar.length - 1) {
      setState(() {
        _currentDhikr = _zahraAdhkar[currentIndex + 1]['text'];
        _target = _zahraAdhkar[currentIndex + 1]['target'];
        _round = _zahraAdhkar[currentIndex + 1]['round'];
        _counter = 0;
      });
    } else {
      setState(() {
        _counter = 0;
        _currentDhikr = _zahraAdhkar[0]['text'];
        _target = _zahraAdhkar[0]['target'];
        _round = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم إكمال تسبيح الزهراء عليها السلام - بدء جولة جديدة')),
      );
    }
  }

  void _reset() {
    setState(() {
      _counter = 0;
      final first = _activeList.first;
      _currentDhikr = first['text'];
      _target = first['target'];
      _round = first['round'] ?? 1;
    });
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  void _selectDhikr(int index) {
    final item = _activeList[index];
    setState(() {
      _currentDhikr = item['text'];
      _target = item['target'];
      _round = item['round'] ?? 1;
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _counter / _target;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المسبحة الإلكترونية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'إعادة البدء',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ✅ مفتاح التبديل بين تسبيح الزهراء والأذكار الأخرى
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_TasbihMode>(
                segments: const [
                  ButtonSegment(
                    value: _TasbihMode.zahra,
                    label: Text('تسبيح الزهراء'),
                    icon: Icon(Icons.spa_outlined),
                  ),
                  ButtonSegment(
                    value: _TasbihMode.other,
                    label: Text('أذكار أخرى'),
                    icon: Icon(Icons.menu_book_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) => _switchMode(selection.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primaryGreen,
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ✅ بطاقة الذكر الحالي
            Card(
              color: AppColors.primaryGreen,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (_mode == _TasbihMode.zahra)
                      Text(
                        'الجولة $_round / ${_zahraAdhkar.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    if (_mode == _TasbihMode.zahra) const SizedBox(height: 12),
                    Text(
                      _currentDhikr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_counter / $_target',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ شريط التقدم الدائري
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_counter',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      Text(
                        '/ $_target',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ✅ زر العد
            SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton(
                onPressed: _increment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'اضغط للتسبيح',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ زر إعادة العد
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'إعادة البدء',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ✅ قائمة أقسام التسبيح الحالية (تتغيّر حسب الوضع المختار)
            Text(
              _mode == _TasbihMode.zahra ? 'أقسام تسبيح الزهراء:' : 'اختر ذكراً:',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _activeList.asMap().entries.map((entry) {
                final index = entry.key;
                final adhkar = entry.value;
                final isSelected = _currentDhikr == adhkar['text'];
                return ChoiceChip(
                  label: Text('${adhkar['text']} (${adhkar['target']})'),
                  selected: isSelected,
                  onSelected: (_) => _selectDhikr(index),
                  selectedColor: AppColors.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
