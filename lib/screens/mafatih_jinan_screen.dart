import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

/// شاشة عرض كتاب مفاتيح الجنان بصيغة PDF، مع دعم الانتقال المباشر
/// لأي رقم صفحة، وفهرس جانبي قابل للإظهار والإخفاء.
class MafatihJinanScreen extends StatefulWidget {
  const MafatihJinanScreen({super.key});

  @override
  State<MafatihJinanScreen> createState() => _MafatihJinanScreenState();
}

/// عنصر بالفهرس: عنوان + رقم الصفحة بالملف
class _IndexEntry {
  final String title;
  final int page;
  const _IndexEntry(this.title, this.page);
}

/// ✅ فهرس مبدئي بعناوين تحقّقنا من رقم صفحتها مباشرة من محتوى الصفحة
/// نفسها (وليس فقط من فهرس الكتاب المطبوع، لأن استخراج الأرقام منه
/// كان غير موثوق بسبب طريقة تظمين الأرقام بخط الكتاب). يمكن إضافة
/// المزيد من العناوين لاحقاً بنفس الطريقة.
const List<_IndexEntry> _bookIndex = [
  _IndexEntry('مقدمة التحقيق', 5),
  _IndexEntry('سورة يس', 9),
  _IndexEntry('سورة العنكبوت', 15),
  _IndexEntry('دعاء كميل بن زياد', 115),
  _IndexEntry('دعاء السمات', 125),
  _IndexEntry('المناجاة الخمس عشرة', 178),
];

class _MafatihJinanScreenState extends State<MafatihJinanScreen> {
  static const String _assetPath = 'assets/books/mafatih_aljanan.pdf';

  String? _localPath;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfController;
  final TextEditingController _pageInputController = TextEditingController();
  bool _showIndex = false;

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  @override
  void dispose() {
    _pageInputController.dispose();
    super.dispose();
  }

  Future<void> _prepareFile() async {
    try {
      final data = await rootBundle.load(_assetPath);
      final dir = await getTemporaryDirectory();
      final fileName = _assetPath.split('/').last;
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

  Future<void> _goToPageNumber(int pageNumber) async {
    if (_pdfController == null || _totalPages == 0) return;
    if (pageNumber < 1 || pageNumber > _totalPages) return;
    await _pdfController!.setPage(pageNumber - 1);
  }

  Future<void> _goToPageFromInput() async {
    final text = _pageInputController.text.trim();
    if (text.isEmpty) return;
    final pageNumber = int.tryParse(text);
    if (pageNumber == null || pageNumber < 1 || pageNumber > _totalPages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أدخل رقم صفحة صحيح بين 1 و $_totalPages')),
      );
      return;
    }
    await _goToPageNumber(pageNumber);
    FocusScope.of(context).unfocus();
    _pageInputController.clear();
  }

  void _showJumpToPageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الانتقال إلى صفحة'),
        content: TextField(
          controller: _pageInputController,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'رقم الصفحة (1 - $_totalPages)',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            Navigator.pop(context);
            _goToPageFromInput();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pageInputController.clear();
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _goToPageFromInput();
            },
            child: const Text('انتقال'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مفاتيح الجنان'),
        actions: [
          if (_totalPages > 0) ...[
            IconButton(
              tooltip: _showIndex ? 'إخفاء الفهرس' : 'إظهار الفهرس',
              icon: Icon(_showIndex ? Icons.menu_open : Icons.menu_book),
              onPressed: () => setState(() => _showIndex = !_showIndex),
            ),
            IconButton(
              tooltip: 'الانتقال إلى صفحة',
              icon: const Icon(Icons.pin_outlined),
              onPressed: _showJumpToPageDialog,
            ),
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
              : Stack(
                  children: [
                    PDFView(
                      filePath: _localPath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      onViewCreated: (controller) {
                        _pdfController = controller;
                      },
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
                    // ✅ الفهرس الجانبي: يظهر فوق الصفحة كـ overlay من
                    // جهة اليمين (لأن الواجهة عربية RTL)، مع طبقة شفافة
                    // خلفه لإغلاقه عند الضغط خارجه.
                    if (_showIndex) ...[
                      GestureDetector(
                        onTap: () => setState(() => _showIndex = false),
                        child: Container(color: Colors.black.withOpacity(0.4)),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 260,
                          height: double.infinity,
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: Theme.of(context).primaryColor,
                                child: const Text(
                                  'الفهرس',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.separated(
                                  itemCount: _bookIndex.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final entry = _bookIndex[index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(
                                        entry.title,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      trailing: Text(
                                        '${entry.page}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      onTap: () {
                                        _goToPageNumber(entry.page);
                                        setState(() => _showIndex = false);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
