import 'package:flutter/material.dart';

/// شاشة قراءة قسم واحد من مفاتيح الجنان (باب/فصل) مع إمكانية
/// تكبير/تصغير الخط، وتمييز الجزء المطابق لعبارة البحث إن وُجدت.
class MafatihSectionScreen extends StatefulWidget {
  final String title;
  final String text;
  final int page;
  final String? highlight;

  const MafatihSectionScreen({
    super.key,
    required this.title,
    required this.text,
    required this.page,
    this.highlight,
  });

  @override
  State<MafatihSectionScreen> createState() => _MafatihSectionScreenState();
}

class _MafatihSectionScreenState extends State<MafatihSectionScreen> {
  double _fontSize = 22;

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(14, 40);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease),
            tooltip: 'تصغير الخط',
            onPressed: () => _changeFontSize(-2),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase),
            tooltip: 'تكبير الخط',
            onPressed: () => _changeFontSize(2),
          ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final style = TextStyle(
      fontSize: _fontSize,
      height: 2.0,
      fontFamily: 'Amiri', // غيّرها لاسم خط عربي آخر تستخدمه بالمشروع إن وُجد
    );

    final query = widget.highlight?.trim();
    if (query == null || query.isEmpty) {
      return SelectableText(widget.text, style: style, textAlign: TextAlign.justify);
    }

    // تمييز عبارة البحث داخل النص
    final spans = <TextSpan>[];
    final lowerText = widget.text;
    final lowerQuery = query;
    int start = 0;
    int index;
    while ((index = lowerText.indexOf(lowerQuery, start)) != -1) {
      if (index > start) {
        spans.add(TextSpan(text: lowerText.substring(start, index)));
      }
      spans.add(TextSpan(
        text: lowerText.substring(index, index + lowerQuery.length),
        style: const TextStyle(backgroundColor: Colors.yellow, color: Colors.black),
      ));
      start = index + lowerQuery.length;
    }
    if (start < lowerText.length) {
      spans.add(TextSpan(text: lowerText.substring(start)));
    }

    return SelectableText.rich(
      TextSpan(style: style.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color), children: spans),
      textAlign: TextAlign.justify,
    );
  }
}
