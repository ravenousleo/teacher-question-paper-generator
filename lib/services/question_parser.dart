import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import '../models/app_models.dart';

/// Local DOCX paragraph importer. It preserves extracted wording and flags
/// ambiguous boundaries and Office Math paragraphs for teacher verification.
/// It does not claim to retain full OOXML formatting/equation layout.
class QuestionParser {
  static List<BankQuestion> parseDocx(List<int> bytes, int marks,
      {String idPrefix = 'q'}) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final file = archive.findFile('word/document.xml');
    if (file == null)
      throw const FormatException(
          'This file does not contain a valid Word document body.');
    final doc = XmlDocument.parse(utf8.decode(file.content as List<int>));
    final paragraphs = doc.findAllElements('w:p');
    final raw = <String>[];
    for (final p in paragraphs) {
      // Text in ordinary runs and Office Math runs is extracted in document order.
      final text =
          p.descendants.whereType<XmlText>().map((e) => e.value).join();
      final normalized = text.replaceAll('\u00a0', ' ').trim();
      if (normalized.isEmpty) continue;
      final isListItem = p
          .findElements('w:pPr')
          .any((pr) => pr.findElements('w:numPr').isNotEmpty);
      final hasMath = p.descendants.any((e) =>
          e is XmlElement &&
          (e.name.local == 'oMath' || e.name.local == 'oMathPara'));
      raw.add(
          '${isListItem ? '§LIST§' : ''}${hasMath ? '§MATH§' : ''}$normalized');
    }
    final result = <BankQuestion>[];
    final numberPattern = RegExp(
        r'^\s*(?:(?:Q(?:uestion)?\s*)?\d{1,3}[.)、:]|[•●▪‣\-])\s*',
        caseSensitive: false);
    var current = '';
    var source = '';
    var uncertain = false;
    void flush() {
      if (current.trim().isNotEmpty) {
        result.add(BankQuestion(
            id: '${idPrefix}_${result.length + 1}',
            text: current.trim(),
            marks: marks,
            sourceNumber: source,
            review: uncertain));
      }
      current = '';
      source = '';
      uncertain = false;
    }

    for (var line in raw) {
      final listItem = line.startsWith('§LIST§');
      final hasMath = line.contains('§MATH§');
      line = line.replaceAll('§LIST§', '').replaceAll('§MATH§', '').trim();
      final match = numberPattern.firstMatch(line);
      if (match != null || listItem) {
        flush();
        source = match?.group(0)?.trim() ?? 'Word numbered/bulleted item';
        current = match == null ? line : line.substring(match.end).trim();
        if (current.isEmpty || hasMath) uncertain = true;
      } else if (current.isEmpty) {
        current = line;
        uncertain = true;
        if (hasMath) uncertain = true;
      } else {
        current = '$current\n$line';
        if (hasMath) uncertain = true;
      }
    }
    flush();
    return result;
  }
}
