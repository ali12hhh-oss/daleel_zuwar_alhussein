import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

/// شاشة عرض PDF عامة قابلة لإعادة الاستخدام لأي كتاب (مفاتيح الجنان،
/// منهاج الصالحين، أو أي كتاب آخر يُضاف مستقبلاً). تنسخ ملف الأصول
/// (asset) إلى ملف مؤقت على الجهاز لأن flutter_pdfview يحتاج مساراً
/// حقيقياً على القرص وليس بيانات أصول مباشرة.
class BookViewerScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const BookViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<BookViewerScreen> createState() => _BookViewerScreenState();
}

class _BookViewerScreenState extends State<BookViewerScreen> {
  String? _localPath;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  Future<void> _prepareFile() async {
    try {
      final data = await rootBundle.load(widget.assetPath);
      final dir = await getTemporaryDirectory();
      final fileName = widget.assetPath.split('/').last;
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      if (mounted) {
        setState(() => _localPath = file.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'تعذّر فتح الكتاب.\nلم يتم إضافة الملف بعد إلى التطبيق، يرجى مراجعة المطوّر.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            )
          : _localPath == null
              ? const Center(child: CircularProgressIndicator())
              : PDFView(
                  filePath: _localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  onRender: (pages) {
                    setState(() => _totalPages = pages ?? 0);
                  },
                  onError: (error) {
                    setState(() => _error = 'حدث خطأ أثناء عرض الملف');
                  },
                  onPageChanged: (page, total) {
                    setState(() => _currentPage = page ?? 0);
                  },
                ),
    );
  }
}
