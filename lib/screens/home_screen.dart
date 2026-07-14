import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/section_card.dart';
import 'route_screen.dart';
import 'scholars_screen.dart';
import 'hussein_quotes_screen.dart';
import 'mawadda_screen.dart';
import 'battle_screen.dart';
import 'sabaya_screen.dart';
import 'ahlulbayt_dates_screen.dart';
import 'settings_screen.dart';
import 'tasbih_screen.dart';
import 'qibla_screen.dart';
import 'ziarat_screen.dart';
import 'prayer_times_screen.dart';
import 'crescent_screen.dart';

class HomeScreen extends StatelessWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل زوار الحسين'),
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Text('السلام عليك يا أبا عبدالله',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('دليلك الشامل لزيارة الإمام الحسين عليه السلام',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SectionCard(
            title: 'طريق زائر الحسين',
            subtitle: 'حدد موقعك واعرف أقرب المسارات إلى كربلاء والمسافة',
            icon: Icons.directions_walk,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RouteScreen())),
          ),
          SectionCard(
            title: 'أسئلة شرعية',
            subtitle: 'اختر المرجع الديني الشيعي واطّلع على الأجوبة الشرعية',
            icon: Icons.menu_book,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ScholarsScreen())),
          ),
          SectionCard(
            title: 'أقوال الإمام الحسين عليه السلام',
            subtitle: 'خطبه وكلماته في كربلاء',
            icon: Icons.format_quote,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HusseinQuotesScreen())),
          ),
          SectionCard(
            title: 'خطب السبايا',
            subtitle: 'خطب أهل البيت السبايا من كربلاء إلى الشام والمدينة',
            icon: Icons.record_voice_over,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SabayaScreen())),
          ),
          SectionCard(
            title: 'مودة أهل البيت عليهم السلام',
            subtitle: 'أحاديث النبي صلى الله عليه وآله في حب أهل البيت',
            icon: Icons.favorite,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MawaddaScreen())),
          ),
          SectionCard(
            title: 'معركة الطف',
            subtitle: 'أحداث الأيام العشرة من محرم في كربلاء',
            icon: Icons.history_edu,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BattleScreen())),
          ),
          SectionCard(
            title: 'ولادات ووفيات أهل البيت',
            subtitle: 'تواريخ ولادة واستشهاد المعصومين عليهم السلام',
            icon: Icons.calendar_month,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AhlulBaytDatesScreen())),
          ),
          SectionCard(
            title: 'مواقيت الصلاة',
            subtitle: 'حسب كتيب مواقيت الصلاة للسيد السيستاني',
            icon: Icons.access_time_filled,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PrayerTimesScreen())),
          ),
          SectionCard(
            title: 'الأهلة',
            subtitle: 'حسب كتيب الأهلة للسيد السيستاني',
            icon: Icons.nightlight_round,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CrescentScreen())),
          ),
          SectionCard(
            title: 'المسبحة الإلكترونية',
            subtitle: 'تسبيح الزهراء عليها السلام والأذكار',
            icon: Icons.fingerprint,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TasbihScreen())),
          ),
          SectionCard(
            title: 'اتجاه القبلة',
            subtitle: 'حساب اتجاه القبلة حسب موقعك',
            icon: Icons.explore,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const QiblaScreen())),
          ),
          SectionCard(
            title: 'الزيارات',
            subtitle: 'زيارة عاشوراء، وارث، الأربعين، العباس، علي الأكبر، الأصحاب',
            icon: Icons.mosque,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ZiaratScreen())),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
