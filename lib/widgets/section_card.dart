import 'package:flutter/material.dart';
import '../theme.dart';

class SectionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // ✅ متحكم الوهج الذهبي: يتقدّم (forward) بسرعة عند الضغط لإظهار
    // الوهج بشكل "نابض" (overshoot خفيف عبر easeOutBack يعطي إحساس
    // النبضة)، ثم يتراجع (reverse) ببطء أكبر عند رفع الإصبع أو إلغاء
    // الضغط ليخفت الوهج تدريجياً بدل أن يختفي فجأة.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 500),
    );
    _glow = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // ✅ نستخدم Listener بدل GestureDetector عمداً: Listener يستمع
      // لأحداث المؤشر الخام مباشرة دون الدخول في "ساحة الإيماءات"
      // (Gesture Arena)، فلا يتعارض إطلاقاً مع تعرّف InkWell على الضغط
      // (onTap) وتأثير الموجة (splash) الخاص به بالأسفل.
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glowValue = _glow.value;
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: glowValue > 0
                    ? [
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.55 * glowValue),
                          blurRadius: 22 * glowValue,
                          spreadRadius: 1.5 * glowValue,
                        ),
                        BoxShadow(
                          color: AppColors.gold.withOpacity(0.28 * glowValue),
                          blurRadius: 38 * glowValue,
                          spreadRadius: 5 * glowValue,
                        ),
                      ]
                    : const [],
              ),
              child: child,
            ),
          );
        },
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            // ✅ نجعل موجة النقر (splash) نفسها ذهبية أيضاً بدل الرمادي
            // الافتراضي، لتنسجم مع الوهج المحيط بالبطاقة.
            splashColor: AppColors.gold.withOpacity(0.25),
            highlightColor: AppColors.gold.withOpacity(0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: AppColors.primaryGreen, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(widget.subtitle,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_back_ios, size: 16, color: AppColors.gold),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
