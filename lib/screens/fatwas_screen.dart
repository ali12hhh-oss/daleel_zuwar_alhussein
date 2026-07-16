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

      final response = await http.get(Uri.parse(widget.scholar.rssUrl!));
      if (response.statusCode != 200) {
        throw Exception('فشل في تحميل الاستفتاءات');
      }

      final document = XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      final fatwas = items.map((item) {
        final title = item.findElements('title').firstOrNull?.text ?? '';
        final link = item.findElements('link').firstOrNull?.text ?? '';
        final description = item.findElements('description').firstOrNull?.text ?? '';
        final pubDateStr = item.findElements('pubDate').firstOrNull?.text ?? '';
        final pubDate = DateTime.tryParse(pubDateStr) ?? DateTime.now();

        return FatwaItem(
          title: title,
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
