import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CrescentScreen extends StatefulWidget {
  const CrescentScreen({super.key});
  @override
  State<CrescentScreen> createState() => _CrescentScreenState();
}

class _CrescentScreenState extends State<CrescentScreen> {
  String? _pdfPath;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      // ✅ نسخ PDF من assets إلى التخزين المؤقت
      final bytes = await rootBundle.load('assets/books/ahilla.pdf');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/ahilla.pdf');

      if (!await file.exists()) {
        await file.writeAsBytes(bytes.buffer.asUint8List());
      }

      setState(() {
        _pdfPath = file.path;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذر تحميل الكتاب';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مواقيت الأهلة')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'سيتم إضافته قريباً',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : PDFView(
                  filePath: _pdfPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                  pageSnap: true,
                  fitPolicy: FitPolicy.BOTH,
                ),
    );
  }
}
