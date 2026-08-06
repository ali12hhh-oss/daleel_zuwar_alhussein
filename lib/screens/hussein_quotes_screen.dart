import 'package:flutter/material.dart';
import '../theme.dart';
import 'ziarat_screen.dart' show ZiaratDetailScreen;

class HusseinQuotesScreen extends StatelessWidget {
  const HusseinQuotesScreen({super.key});

  final List<Map<String, dynamic>> quotesList = const [
    {
      'title': 'إني لا أرى الموت إلا سعادة',
      'subtitle': 'خطبته عليه السلام في مسيره إلى كربلاء',
      'icon': Icons.format_quote,
      'content': '''إنَّ هذِهِ الدُّنيا قَد تَغَيَّرَت وتَنَكَّرَت، وأدبَرَ مَعروفُها، فَلَم يَبقَ مِنها إلّا صُبابَةٌ كَصُبابَةِ الإِناءِ، وخَسيسُ عَيشٍ كَالمَرعى الوَبيلِ. ألا تَرَونَ أنّ الحَقَّ لا يُعمَلُ بِهِ، وأنَّ الباطِلَ لا يُتَناهى عَنهُ! لِيَرغَبِ المُؤمِنُ في لِقاءِ اللهِ مُحِقّاً؛ فَإِنّي لا أرى المَوتَ إلّا سَعادَةً، وَالحَياةَ مَعَ الظّالِمينَ إلّا بَرَماً.

إنَّ النّاسَ عَبيدُ الدُّنيا، وَالدّينُ لَعِقٌ عَلى أَلسِنَتِهِمْ، يَحوطونَهُ ما دَرَّتْ مَعايِشُهُمْ، فَإِذا مُحِّصوا بِالبَلاءِ قَلَّ الدَّيّانونَ.''',
    },
    {
      'title': 'إني لم أخرج أشراً ولا بطراً',
      'subtitle': 'بيان أهداف نهضته عليه السلام',
      'icon': Icons.format_quote,
      'content': '''إنّي لَمْ أَخْرُجْ أَشِراً وَلا بَطِراً، وَلا مُفْسِداً وَلا ظالِماً، وَإِنَّما خَرَجْتُ لِطَلَبِ الإِصْلاحِ في أُمَّةِ جَدّي صَلَّى اللهُ عَلَيهِ وَآلِهِ، أُريدُ أَنْ آمُرَ بِالْمَعْروفِ وَأَنْهى عَنِ الْمُنْكَرِ، وَأَسيرَ بِسيرَةِ جَدّي وَأَبي عَلِيِّ بْنِ أَبي طالِب عَلَيْهِ السَّلامُ.''',
    },
    {
      'title': 'الموت أولى من ركوب العار',
      'subtitle': 'قوله عليه السلام في مواجهة جيش يزيد',
      'icon': Icons.format_quote,
      'content': '''أَلا وَإِنَّ الدَّعِيَّ ابْنَ الدَّعِيِّ قَدْ رَكَزَ بَيْنَ اثْنَتَيْنِ: بَيْنَ السِّلَّةِ وَالذِّلَّةِ، وَهَيْهاتَ مِنَّا الذِّلَّةُ، يَأْبى اللهُ ذلِكَ لَنا وَرَسُولُهُ وَالْمُؤْمِنونَ، وَحُجورٌ طابَتْ وَطَهُرَتْ، وَأُنوفٌ حَمِيَّةٌ، وَنُفوسٌ أَبِيَّةٌ، مِنْ أَنْ نُؤْثِرَ طاعَةَ اللِّئامِ عَلى مَصارِعِ الْكِرامِ.

مَوْتٌ في عِزٍّ خَيْرٌ مِنْ حَياة في ذُلٍّ.''',
    },
    {
      'title': 'والله لا أعطيكم بيدي إعطاء الذليل',
      'subtitle': 'ردّه عليه السلام على طلب البيعة ليزيد',
      'icon': Icons.format_quote,
      'content': '''وَاللهِ لا أُعْطيكُمْ بِيَدي إِعْطاءَ الذَّليلِ، وَلا أُقِرُّ إِقْرارَ الْعَبيدِ، عِبادَ اللهِ أُعوذُ بِرَبّي وَرَبِّكُمْ مِنْ كُلِّ مُتَكَبِّر لا يُؤْمِنُ بِيَوْمِ الْحِسابِ.''',
    },
    {
      'title': 'العلم لقاح المعرفة',
      'subtitle': 'من حِكَمه عليه السلام',
      'icon': Icons.format_quote,
      'content': '''العِلْمُ لِقاحُ الْمَعْرِفَةِ، وَطولُ التَّجارِبِ زِيادَةٌ فِي الْعَقْلِ، وَالشَّرَفُ التَّقْوى، وَالْقُنوعُ راحَةُ الأَبْدانِ، وَمَنْ أَحَبَّكَ نَهاكَ، وَمَنْ أَبْغَضَكَ أَغْراكَ.

إِذا سَمِعْتَ أَحَداً يَتَناوَلُ أَعْراضَ النّاسِ فَاجْتَهِدْ أَنْ لا يَعْرِفَكَ.''',
    },
    {
      'title': 'نافسوا في المكارم',
      'subtitle': 'خطبته عليه السلام في مكارم الأخلاق',
      'icon': Icons.format_quote,
      'content': '''يا أَيُّهَا النّاسُ نافِسوا في الْمَكارِمِ، وَسارِعوا في الْمَغانِمِ، وَلا تَحْتَسِبوا بِمَعْروفٍ لَمْ تُعَجِّلوهُ، وَاكْسِبُوا الْحَمْدَ بِالنُّجْحِ، وَلا تَكْتَسِبوا بِالْمَطْلِ ذَمّاً، فَمَهْما يَكُنْ لأَحَد عِنْدَ أَحَد صَنيعَةٌ لَهُ رَأى أَنَّهُ لا يَقومُ بِشُكْرِها، فَاللهُ لَهُ بِمُكافاتِهِ، فَإِنَّهُ أَجْزَلُ عَطاءً وَأَعْظَمُ أَجْراً.''',
    },
    {
      'title': 'الغيبة إدام كلاب النار',
      'subtitle': 'نصيحته عليه السلام لرجل اغتاب عنده أحداً',
      'icon': Icons.format_quote,
      'content': '''يا هذا، كُفَّ عَنِ الْغيبَةِ، فَإِنَّها إِدامُ كِلابِ النّارِ.''',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أقوال الإمام الحسين عليه السلام')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.lightGold.withOpacity(0.3),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.format_quote, size: 48, color: AppColors.primaryGreen),
                  SizedBox(height: 12),
                  Text(
                    'أقوال الإمام الحسين عليه السلام',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'خطبه وكلماته في مسيره إلى كربلاء وفي واقعة الطف',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...quotesList.map((quote) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                quote['icon'] as IconData,
                color: AppColors.primaryGreen,
                size: 32,
              ),
              title: Text(
                quote['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                quote['subtitle'] as String,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ZiaratDetailScreen(
                      title: quote['title'] as String,
                      content: quote['content'] as String,
                    ),
                  ),
                );
              },
            ),
          )),
        ],
      ),
    );
  }
}
