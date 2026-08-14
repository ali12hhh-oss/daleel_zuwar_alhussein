import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/section_card.dart';
import '../widgets/hijri_date_badge.dart';
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
import 'shrines_compass_screen.dart';
import 'duas_ziarat_screen.dart';
import 'prayer_times_screen.dart';
import 'qada_prayer_screen.dart';
import 'crescent_screen.dart';
import 'books_screen.dart';

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
        // ✅ شارة التاريخ الهجري انتقلت من actions (يمين) إلى leading
        // (يسار)، وصار اسم التطبيق بالنص بلون أبيض وإطار ذهبي.
        leading: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: HijriDateBadge(),
        ),
        leadingWidth: 90,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'دليل الزائر',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
                Text('اللهم صل على محمد وال محمد ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('دليلك الشامل لزيارة المراقد والاماكن المقدسة',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 1.طريق الزائر 
          SectionCard(
            title: 'دليل مسار الزائر',
            subtitle: 'حدد موقعك واعرف أقرب المسارات',
            icon: Icons.directions_walk,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RouteScreen())),
          ),

          // 2. أسئلة شرعية
          SectionCard(
            title: 'المسائل الشرعية',
            subtitle: 'اختر المرجع الديني واطّلع على الأجوبة الشرعية',
            icon: Icons.menu_book,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ScholarsScreen())),
          ),

          // 3. مواقيت الصلاة
          SectionCard(
            title: 'مواقيت الصلاة',
            subtitle: 'حسب كتيب مواقيت الصلاة للسيد السيستاني',
            icon: Icons.access_time_filled,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrayerTimesScreen())),
          ),
          
          // 4. قضاء الصلاة
          SectionCard(
            title: 'قضاء الصلاة',
            subtitle: 'متابعة الصلوات الفائتة وخطة القضاء وسجل الإنجاز',
            icon: Icons.check_circle_outline,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const QadaPrayerScreen())),
         ),
          
          // 4. اتجاه القبلة
          SectionCard(
            title: 'اتجاه القبلة',
            subtitle: 'حساب اتجاه القبلة حسب موقعك',
            icon: Icons.explore,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const QiblaScreen())),
          ),

          // 5. اتجاه مراقد المعصومين (ع)
          SectionCard(
            title: 'اتجاه مراقد المعصومين (ع)',
            subtitle: 'حدد موقع المراقد الشريفة والاماكن المقدسة حسب موقعك',
            icon: Icons.explore_outlined,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ShrinesCompassScreen())),
          ),

          // 6. مواقيت الأهلة
          SectionCard(
            title: 'مواقيت الأهلة',
            subtitle: 'حسب كراس الأهلة للسيد السيستاني',
            icon: Icons.nightlight_round,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CrescentScreen())),
          ),

          // 7. الأدعية والزيارات
          SectionCard(
            title: 'الأدعية والزيارات',
            subtitle: 'بعض الزيارات والادعية, لمراجعة كل الزيارات والادعية راجع قسم المكتبة',
            icon: Icons.mosque,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DuasZiaratScreen())),
          ),

          // 8. المكتبة
          SectionCard(
            title: 'المكتبة',
            subtitle: 'القرآن الكريم، مفاتيح الجنان، الصحيفة السجادية ',
            icon: Icons.library_books,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BooksScreen())),
          ),

          // 9. المسبحة الإلكترونية
          SectionCard(
            title: 'المسبحة الإلكترونية',
            subtitle: 'تسبيح الزهراء عليها السلام والأذكار',
            icon: Icons.fingerprint,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TasbihScreen())),
          ),

          // 10. ولادات ووفيات أهل البيت
          SectionCard(
            title: 'ولادات ووفيات أهل البيت',
            subtitle: 'تواريخ ولادة واستشهاد المعصومين عليهم السلام',
            icon: Icons.calendar_month,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AhlulBaytDatesScreen())),
          ),

          // 11. أقوال الإمام الحسين عليه السلام
          SectionCard(
            title: 'أقوال الإمام الحسين عليه السلام',
            subtitle: 'خطبه وكلماته في كربلاء',
            icon: Icons.format_quote,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HusseinQuotesScreen())),
          ),

          // 12. أحداث معركة الطف
          SectionCard(
            title: 'احداث معركة الطف',
            subtitle: 'أحداث الأيام العشرة من محرم في كربلاء',
            icon: Icons.history_edu,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BattleScreen())),
          ),

          // 13. خطب اهل البيت (السبايا)
          SectionCard(
            title: 'خطب اهل البيت ',
            subtitle: 'خطب أهل البيت السبايا من كربلاء إلى الشام والمدينة',
            icon: Icons.record_voice_over,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SabayaScreen())),
          ),

          // 14. مودة أهل البيت عليهم السلام
          SectionCard(
            title: 'مودة أهل البيت عليهم السلام',
            subtitle: 'أحاديث النبي صلى الله عليه وآله في حب أهل البيت',
            icon: Icons.favorite,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MawaddaScreen())),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
