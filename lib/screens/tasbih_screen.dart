import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../theme.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _counter = 0;
  int _target = 33;
  String _currentDhikr = 'سبحان الله';
  int _round = 1;

  final List<Map<String, dynamic>> _adhkar = [
    {'text': 'سبحان الله', 'target': 33, 'round': 1},
    {'text': 'الحمد لله', 'target': 33, 'round': 2},
    {'text': 'الله أكبر', 'target': 34, 'round': 3},
    {'text': 'أستغفر الله', 'target': 33, 'round': 4},
    {'text': 'لا حول ولا قوة إلا بالله', 'target': 33, 'round': 5},
    {'text': 'سبحان الله وبحمده سبحان الله العظيم', 'target': 33, 'round': 6},
    {'text': 'اللهم صل على محمد وآل محمد', 'target': 33, 'round': 7},
  ];

  void _increment() {
    setState(() {
      _counter++;
      if (_counter >= _target) {
        _vibrate();
        _nextDhikr();
      }
    });
  }

  void _nextDhikr() {
    final currentIndex = _adhkar.indexWhere((a) => a['text'] == _currentDhikr);
    if (currentIndex < _adhkar.length - 1) {
      setState(() {
        _currentDhikr = _adhkar[currentIndex + 1]['text'];
        _target = _adhkar[currentIndex + 1]['target'];
        _round = _adhkar[currentIndex + 1]['round'];
        _counter = 0;
      });
    } else {
      setState(() {
        _counter = 0;
        _currentDhikr = _adhkar[0]['text'];
        _target = _adhkar[0]['target'];
        _round = 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إكمال جميع الأذكار - بدء جديد')),
      );
    }
  }

  void _reset() {
    setState(() {
      _counter = 0;
      _currentDhikr = _adhkar[0]['text'];
      _target = _adhkar[0]['target'];
      _round = 1;
    });
  }

  Future<void> _vibrate() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }
  }

  void _selectDhikr(int index) {
    setState(() {
      _currentDhikr = _adhkar[index]['text'];
      _target = _adhkar[index]['target'];
      _round = _adhkar[index]['round'];
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
            // ✅ بطاقة الذكر الحالي
            Card(
              color: AppColors.primaryGreen,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'الجولة $_round / ${_adhkar.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
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

            // ✅ قائمة الأذكار
            const Text(
              'اختر ذكراً:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _adhkar.asMap().entries.map((entry) {
                final index = entry.key;
                final adhkar = entry.value;
                final isSelected = _currentDhikr == adhkar['text'];
                return ChoiceChip(
                  label: Text(adhkar['text']),
                  selected: isSelected,
                  onSelected: (_) => _selectDhikr(index),
                  selectedColor: AppColors.primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
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
