import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/app_models.dart';

class ExportService {
  static String _xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static Uint8List docx(ExamDetails d, List<BankQuestion> questions) {
    final body = StringBuffer();

    void para(
      String text, {
      bool bold = false,
      int size = 22,
      String align = 'left',
    }) {
      body.write(
        '<w:p><w:pPr><w:jc w:val="$align"/></w:pPr><w:r><w:rPr>'
        '${bold ? '<w:b/>' : ''}<w:sz w:val="$size"/></w:rPr>'
        '<w:t xml:space="preserve">${_xml(text)}</w:t></w:r></w:p>',
      );
    }

    para(
      d.schoolName.isEmpty ? 'SCHOOL / INSTITUTE NAME' : d.schoolName,
      bold: true,
      size: 30,
      align: 'center',
    );
    para(d.examName, bold: true, size: 26, align: 'center');
    para(
      '${d.standard}  |  ${d.subject}  |  ${d.board}',
      bold: true,
      align: 'center',
    );

    if (d.academicYear.isNotEmpty) {
      para('Academic Year: ${d.academicYear}', align: 'center');
    }

    para(
      'Date: ${d.examDate}     Duration: ${d.duration}     '
      'Maximum Marks: ${questions.fold<int>(0, (s, q) => s + q.marks)}',
    );
    para('');
    para('Instructions', bold: true);

    for (final line in d.instructions.split('\n')) {
      if (line.trim().isNotEmpty) {
        para(line);
      }
    }

    final grouped = <int, List<BankQuestion>>{};
    for (final q in questions) {
      grouped.putIfAbsent(q.marks, () => []).add(q);
    }

    var number = 1;
    var section = 0;

    for (final marks in grouped.keys.toList()..sort()) {
      section++;
      para(
        'Section ${String.fromCharCode(64 + section)} – $marks Mark '
        'Question${marks == 1 ? '' : 's'}',
        bold: true,
        size: 24,
      );

      for (final q in grouped[marks]!) {
        para('$number. ${q.text}  [${q.marks}]');
        number++;
      }
    }

    body.write(
      '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
      '<w:pgMar w:top="900" w:right="900" w:bottom="900" w:left="900"/>'
      '</w:sectPr>',
    );

    final document =
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>${body.toString()}</w:body></w:document>''';

    final archive = Archive();

    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }

    add(
      '[Content_Types].xml',
      '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''',
    );
    add(
      '_rels/.rels',
      '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''',
    );
    add('word/document.xml', document);

    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  /// Creates a Unicode-safe PDF using fonts bundled with the application.
  ///
  /// The fonts are loaded from local Flutter assets, so PDF generation does
  /// not require an internet connection.
  static Future<Uint8List> pdf(
    ExamDetails d,
    List<BankQuestion> questions,
  ) async {
    final regularFont = await _loadFont('assets/fonts/NotoSans-Regular.ttf');
    final boldFont = await _loadFont('assets/fonts/NotoSans-Bold.ttf');
    final mathFont =
        await _loadFont('assets/fonts/NotoSansMath-Regular.ttf');
    final symbolsFont =
        await _loadFont('assets/fonts/NotoSansSymbols-Regular.ttf');
    final symbols2Font =
        await _loadFont('assets/fonts/NotoSansSymbols2-Regular.ttf');

    final fallbackFonts = <pw.Font>[
      mathFont,
      symbolsFont,
      symbols2Font,
    ];

    final normalStyle = pw.TextStyle(
      font: regularFont,
      fontFallback: fallbackFonts,
      fontSize: 10,
      color: PdfColors.grey900,
    );

    final boldStyle = pw.TextStyle(
      font: boldFont,
      fontFallback: fallbackFonts,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey900,
    );

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
    );

    final grouped = <int, List<BankQuestion>>{};
    for (final q in questions) {
      grouped.putIfAbsent(q.marks, () => []).add(q);
    }

    final sortedMarks = grouped.keys.toList()..sort();
    final totalMarks = questions.fold<int>(0, (sum, q) => sum + q.marks);
    var questionNo = 1;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 36, 42, 42),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber}',
            style: normalStyle.copyWith(fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              d.schoolName.isEmpty
                  ? 'SCHOOL / INSTITUTE NAME'
                  : d.schoolName,
              textAlign: pw.TextAlign.center,
              style: boldStyle.copyWith(fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Center(
            child: pw.Text(
              d.examName,
              textAlign: pw.TextAlign.center,
              style: boldStyle.copyWith(fontSize: 13),
            ),
          ),
          pw.Center(
            child: pw.Text(
              '${d.standard}  |  ${d.subject}  |  ${d.board}',
              textAlign: pw.TextAlign.center,
              style: normalStyle.copyWith(fontSize: 9.5),
            ),
          ),
          if (d.academicYear.isNotEmpty)
            pw.Center(
              child: pw.Text(
                'Academic Year: ${d.academicYear}',
                style: normalStyle,
              ),
            ),
          pw.SizedBox(height: 10),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 5),
          pw.Text(
            'Date: ${d.examDate}     Duration: ${d.duration}     '
            'Maximum Marks: $totalMarks',
            style: normalStyle,
          ),
          pw.SizedBox(height: 12),
          pw.Text('Instructions', style: boldStyle),
          pw.Text(d.instructions, style: normalStyle),
          pw.SizedBox(height: 12),
          ...sortedMarks.map((marks) {
            final sectionIndex = sortedMarks.indexOf(marks);
            final sectionQuestions = grouped[marks]!;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Section ${String.fromCharCode(65 + sectionIndex)} – '
                  '$marks Mark ${marks == 1 ? 'Questions' : 'Questions'}',
                  style: boldStyle.copyWith(fontSize: 11),
                ),
                pw.SizedBox(height: 7),
                ...sectionQuestions.map((question) {
                  final number = questionNo++;

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 9),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '$number. ${question.text}',
                            style: normalStyle,
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Text(
                          '[${question.marks}]',
                          style: normalStyle,
                        ),
                      ],
                    ),
                  );
                }),
                pw.SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );

    return doc.save();
  }

  static Future<pw.Font> _loadFont(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    return pw.Font.ttf(data);
  }
}
