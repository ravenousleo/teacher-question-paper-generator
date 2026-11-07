import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_question_paper_generator/services/question_parser.dart';

List<int> _docx(String body) {
  final archive=Archive();
  final xml='''<?xml version="1.0"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>$body</w:body></w:document>''';
  final bytes=utf8.encode(xml);
  archive.addFile(ArchiveFile('word/document.xml',bytes.length,bytes));
  return ZipEncoder().encode(archive)!;
}
String _p(String text)=>'<w:p><w:r><w:t>$text</w:t></w:r></w:p>';
void main(){
  test('splits explicitly numbered paragraphs and joins continuation lines',(){
    final bytes=_docx(_p('1. First question')+_p('continued on next paragraph')+_p('2. Second question'));
    final result=QuestionParser.parseDocx(bytes,2);
    expect(result.length,2);
    expect(result.first.text,'First question\ncontinued on next paragraph');
    expect(result.last.text,'Second question');
  });
  test('imports a large numbered question set without an artificial cap',(){
    final body=List.generate(500,(i)=>_p('${i+1}. Sample question ${i+1}')).join();
    final result=QuestionParser.parseDocx(_docx(body),1);
    expect(result.length,500);
  });
}
