import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// شاشة عرض كتاب PDF لا يُشحن مع التطبيق، بل يُحمَّل من الإنترنت عند أول
/// فتح فقط، ثم يُخزَّن على الجهاز للاستخدام اللاحق بدون إنترنت.
/// هذا يبقي حجم التطبيق (APK) صغيراً بدل تضمين ملفات PDF كبيرة بداخله.
class RemoteBookViewerScreen extends StatefulWidget {
  final String title;
  final String remoteUrl;
  final String cacheFileName;

  const RemoteBookViewerScreen({
    super.key,
    required this.title,
    required this.remoteUrl,
    required this.cacheFileName,
  });

  @override
  State<RemoteBookViewerScreen> createState() =>
      _RemoteBookViewerScreenState();
}

class _RemoteBookViewerScreenState extends State<RemoteBookViewerScreen> {
  String? _localPath;
  String? _error;
  bool _downloading = false;
  double? _downloadProgress;
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  Future<void> _prepareFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.cacheFileName}');

      // إذا الكتاب محمّل مسبقاً، افتحه مباشرة بدون إنترنت
      if (await file.exists()) {
        if (mounted) setState(() => _localPath = file.path);
        return;
      }

      setState(() {
        _downloading = true;
        _downloadProgress = null;
      });

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.remoteUrl));
      final response =
          await client.send(request).timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        throw Exception('فشل التحميل (${response.statusCode})');
      }

      final total = response.contentLength;
      final bytes = <int>[];
      int received = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total != null && total > 0 && mounted) {
          setState(() => _downloadProgress = received / total);
        }
      }
      client.close();

      await file.writeAsBytes(bytes);

      if (mounted) {
        setState(() {
          _localPath = file.path;
          _downloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'تعذّر تحميل الكتاب.\nتأكد من الاتصال بالإنترنت ثم أعد المحاولة.';
          _downloading = false;
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _prepareFile();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_downloading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_downloadProgress != null) ...[
                CircularProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 16),
                Text('${(_downloadProgress! * 100).toStringAsFixed(0)}%'),
              ] else ...[
                const CircularProgressIndicator(),
              ],
              const SizedBox(height: 12),
              const Text('جاري تحميل الكتاب لأول مرة...'),
            ],
          ),
        ),
      );
    }

    if (_localPath == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return PDFView(
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
    );
  }
}
