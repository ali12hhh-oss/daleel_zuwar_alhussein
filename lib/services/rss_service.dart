import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart';
import 'package:xml/xml.dart';
import '../models/models.dart';

class RssService {
  static final _unescape = HtmlUnescape();

  /// جلب الاستفتاءات من RSS
  static Future<List<FatwaItem>> fetchFatwas(String rssUrl, String scholarId) async {
    try {
      final response = await http.get(
        Uri.parse(rssUrl),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return _parseRss(response.body, scholarId);
      }
      throw Exception('فشل في تحميل RSS: ${response.statusCode}');
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  static List<FatwaItem> _parseRss(String xmlString, String scholarId) {
    final items = <FatwaItem>[];
    try {
      final document = XmlDocument.parse(xmlString);
      final rssItems = document.findAllElements('item');
      for (final item in rssItems) {
        final title = _getText(item, 'title');
        final link = _getText(item, 'link');
        final description = _getText(item, 'description');
        final pubDateStr = _getText(item, 'pubDate');
        if (title.isNotEmpty && link.isNotEmpty) {
          items.add(FatwaItem(
            title: _cleanText(title),
            link: link,
            description: _cleanText(description),
            pubDate: _parseDate(pubDateStr),
            scholarId: scholarId,
          ));
        }
      }
    } catch (e) {
      // إذا فشل XML parsing، نحاول طريقة بديلة
      items.addAll(_parseRssFallback(xmlString, scholarId));
    }
    return items;
  }

  static String _getText(XmlElement item, String tagName) {
    final element = item.findElements(tagName).firstOrNull;
    return element?.innerText ?? '';
  }

  static String _cleanText(String text) {
    return _unescape
        .convert(text)
        .replaceAll(RegExp(r'<[^>]*>'), '') // إزالة HTML tags
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .trim();
  }

  static DateTime _parseDate(String dateStr) {
    try {
      return HttpDate.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// طريقة بديلة لقراءة RSS
  static List<FatwaItem> _parseRssFallback(String xmlString, String scholarId) {
    final items = <FatwaItem>[];
    final titleRegex = RegExp(r'<title>(.*?)</title>', dotAll: true);
    final linkRegex = RegExp(r'<link>(.*?)</link>', dotAll: true);
    final descRegex = RegExp(r'<description>(.*?)</description>', dotAll: true);
    final titles = titleRegex.allMatches(xmlString).toList();
    final links = linkRegex.allMatches(xmlString).toList();
    final descs = descRegex.allMatches(xmlString).toList();
    final count = [titles.length, links.length, descs.length].reduce((a, b) => a < b ? a : b);
    for (int i = 0; i < count; i++) {
      items.add(FatwaItem(
        title: _cleanText(titles[i].group(1) ?? ''),
        link: links[i].group(1) ?? '',
        description: i < descs.length ? _cleanText(descs[i].group(1) ?? '') : '',
        pubDate: DateTime.now(),
        scholarId: scholarId,
      ));
    }
    return items;
  }
}
