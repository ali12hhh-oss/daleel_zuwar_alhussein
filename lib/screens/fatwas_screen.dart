import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart';
import '../models/models.dart';
import '../theme.dart';

class FatwasScreen extends StatefulWidget {
  final Scholar scholar;
  const FatwasScreen({super.key, required this.scholar});

  @override
  State<FatwasScreen> createState() => _FatwasScreenState();
}

class _FatwasScreenState extends State<FatwasScreen> {
  List<FatwaItem> _fatwas = [];
  bool _loading = true;
  String? _error;

  // ✅ ترويسات تحاكي متصفح حقيقي. بعض المواقع (مثل arabic.khamenei.ir)
  // تكتشف الطلبات الآلية (بدون User-Agent مألوف) وتدخلها في حلقة
  // إعادة توجيه (redirect loop) بدل إرجاع المحتوى مباشرة، وهذا كان
  // سبب خطأ "ClientException: Redirect loop detected".
  static const Map<String, String> _requestHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
    'Accept': 'application/rss+xml, application/xml, text/xml, */*',
  };

  @override
  void initState() {
    super.initState();
    _loadFatwas();
  }

  Future<void> _loadFatwas() async {
    try {
      if (widget.scholar.rssUrl == null || widget.scholar.rssUrl!.isEmpty) {
        setState(() {
          _error = 'لا يوجد رابط RSS لهذا المرجع';
          _loading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(widget.scholar.rssUrl!),
        headers: _requestHeaders,
      );
      if (response.statusCode != 200) {
        throw Exception('فشل في تحميل الاستفتاءات (رمز ${response.statusCode})');
      }

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      final fatwas = items.map((item) {
        final title = _getXmlText(item, 'title');
        final link = _getXmlText(item, 'link');
        // ✅ إصلاح: وصف RSS (description) يأتي غالباً كـ HTML كامل
        // مغلّف بـ CDATA (فقرات <p>، روابط <a>، قوائم <ul>/<li>). كان
        // يُمرَّر خاماً كما هو إلى Text() التي لا تُفسّر HTML إطلاقاً،
        // فتظهر الوسوم حرفياً على الشاشة بدل نص منسّق. _stripHtml
        // يزيل الوسوم ويحوّل الرموز المُرمّزة (&nbsp; ونحوها) إلى نص
        // عادي مقروء.
        final description = _stripHtml(_getXmlText(item, 'description'));
        final pubDateStr = _getXmlText(item, 'pubDate');
        final pubDate = DateTime.tryParse(pubDateStr) ?? DateTime.now();

        return FatwaItem(
          // ✅ إذا العنوان فارغ (حالات نادرة قد تبقى رغم إصلاح CDATA)،
          // نعرض نص بديل بدل بطاقة فارغة بلا أي محتوى مقروء.
          title: title.isNotEmpty ? title : 'استفتاء جديد',
          link: link,
          description: description,
          pubDate: pubDate,
          scholarId: widget.scholar.id,
        );
      }).toList();

      setState(() {
        _fatwas = fatwas;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// ✅ يستخرج نص العنصر بشكل موثوق، شامل محتوى CDATA. الاعتماد سابقاً
  /// على `element.value` كان يرجع نص فارغ لعناصر RSS القياسية اللي
  /// تُغلَّف عناوينها بـ CDATA (وهذا شائع جداً بخلاصات RSS لتفادي مشاكل
  /// رموز مثل & و< الخاصة). `innerText` يجمع كل النصوص الفرعية (نص عادي
  /// + CDATA) بشكل صحيح.
  String _getXmlText(XmlElement item, String elementName) {
    final elements = item.findElements(elementName);
    if (elements.isEmpty) return '';
    return elements.first.innerText.trim();
  }

  /// ✅ يزيل وسوم HTML من نص خام (مثل وصف RSS)، ويحوّل أشهر الرموز
  /// المُرمّزة (HTML entities) إلى ما يقابلها من نص عادي، ثم يضغط أي
  /// مسافات متكررة ناتجة عن إزالة الوسوم إلى مسافة واحدة.
  String _stripHtml(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('استفتاءات ${widget.scholar.name}'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFatwas,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFatwas,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_fatwas.isEmpty) {
      return const Center(
        child: Text('لا توجد استفتاءات متاحة حالياً'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _fatwas.length,
      itemBuilder: (context, index) {
        final fatwa = _fatwas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryGreen,
              child: const Icon(Icons.question_answer, color: Colors.white),
            ),
            title: Text(
              fatwa.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (fatwa.description.isNotEmpty)
                  Text(
                    fatwa.description.length > 100
                        ? '${fatwa.description.substring(0, 100)}...'
                        : fatwa.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(fatwa.pubDate),
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openLink(fatwa.link),
          ),
        );
      },
    );
  }
}
