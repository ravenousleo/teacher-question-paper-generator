import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
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
    void para(String text,
        {bool bold = false, int size = 22, String align = 'left'}) {
      body.write(
          '<w:p><w:pPr><w:jc w:val="$align"/></w:pPr><w:r><w:rPr>${bold ? '<w:b/>' : ''}<w:sz w:val="$size"/></w:rPr><w:t xml:space="preserve">${_xml(text)}</w:t></w:r></w:p>');
    }

    para(d.schoolName.isEmpty ? 'SCHOOL / INSTITUTE NAME' : d.schoolName,
        bold: true, size: 30, align: 'center');
    para(d.examName, bold: true, size: 26, align: 'center');
    para('${d.standard}  |  ${d.subject}  |  ${d.board}',
        bold: true, align: 'center');
    if (d.academicYear.isNotEmpty)
      para('Academic Year: ${d.academicYear}', align: 'center');
    para(
        'Date: ${d.examDate}     Duration: ${d.duration}     Maximum Marks: ${questions.fold<int>(0, (s, q) => s + q.marks)}');
    para('');
    para('Instructions', bold: true);
    for (final line in d.instructions.split('\n')) {
      if (line.trim().isNotEmpty) para(line);
    }
    final grouped = <int, List<BankQuestion>>{};
    for (final q in questions) {
      grouped.putIfAbsent(q.marks, () => []).add(q);
    }
    var n = 1;
    var section = 0;
    for (final marks in grouped.keys.toList()..sort()) {
      section++;
      para(
          'Section ${String.fromCharCode(64 + section)} – $marks Mark Question${marks == 1 ? '' : 's'}',
          bold: true,
          size: 24);
      for (final q in grouped[marks]!) {
        para('$n. ${q.text}  [${q.marks}]');
        n++;
      }
    }
    body.write(
        '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="900" w:right="900" w:bottom="900" w:left="900"/></w:sectPr>');
    final document =
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>${body.toString()}</w:body></w:document>''';
    final archive = Archive();
    void add(String name, String content) => archive.addFile(
        ArchiveFile(name, utf8.encode(content).length, utf8.encode(content)));
    add('[Content_Types].xml',
        '''<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>''');
    add('_rels/.rels',
        '''<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>''');
    add('word/document.xml', document);
    return Uint8List.fromList(ZipEncoder().encode(archive)!);
  }

  static Future<Uint8List> pdf(
      ExamDetails d, List<BankQuestion> questions) async {
    final doc = pw.Document();
    final grouped = <int, List<BankQuestion>>{};
    for (final q in questions) {
      grouped.putIfAbsent(q.marks, () => []).add(q);
    }
    final sortedMarks = grouped.keys.toList()..sort();
    var questionNo = 1;
    doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        footer: (c) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${c.pageNumber}',
                style: const pw.TextStyle(fontSize: 9))),
        build: (context) => [
              pw.Center(
                  child: pw.Text(
                      d.schoolName.isEmpty
                          ? 'SCHOOL / INSTITUTE NAME'
                          : d.schoolName,
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 5),
              pw.Center(
                  child: pw.Text(d.examName,
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold))),
              pw.Center(
                  child:
                      pw.Text('${d.standard}  |  ${d.subject}  |  ${d.board}')),
              if (d.academicYear.isNotEmpty)
                pw.Center(child: pw.Text('Academic Year: ${d.academicYear}')),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Date: ${d.examDate}     Duration: ${d.duration}     Maximum Marks: ${questions.fold<int>(0, (s, q) => s + q.marks)}'),
              pw.Divider(),
              pw.Text('Instructions',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(d.instructions),
              pw.SizedBox(height: 12),
              ...sortedMarks.map((m) => pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            'Section ${String.fromCharCode(65 + sortedMarks.indexOf(m))} – $m Mark Questions',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 6),
                        ...grouped[m]!.map((q) {
                          final number = questionNo++;
                          return pw.Padding(
                              padding: const pw.EdgeInsets.only(bottom: 10),
                              child: pw.Row(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Expanded(
                                        child: pw.Text('$number. ${q.text}')),
                                    pw.Text('[${q.marks}]')
                                  ]));
                        }),
                        pw.SizedBox(height: 8)
                      ]))
            ]));
    return doc.save();
  }
}
