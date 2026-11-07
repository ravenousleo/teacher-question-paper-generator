import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_question_paper_generator/models/app_models.dart';
import 'package:teacher_question_paper_generator/services/paper_engine.dart';

void main() {
  final bank = List.generate(
      20,
      (i) =>
          BankQuestion(id: 'q$i', text: 'Question $i', marks: i < 10 ? 1 : 2));
  test('calculates marks correctly', () {
    expect(PaperEngine.totalMarks([bank[0], bank[10]]), 3);
  });
  test('generates requested counts without duplicates', () {
    final paper = PaperEngine.generate(bank, {1: 5, 2: 4}, random: Random(2));
    expect(paper.length, 9);
    expect(paper.map((q) => q.id).toSet().length, 9);
    expect(paper.where((q) => q.marks == 1).length, 5);
  });
  test('honours exclusions', () {
    expect(
        () => PaperEngine.generate(bank, {
              1: 5
            }, excluded: {
              'q0',
              'q1',
              'q2',
              'q3',
              'q4',
              'q5',
              'q6',
              'q7',
              'q8',
              'q9'
            }),
        throwsStateError);
  });
  test('rejects unavailable combination', () {
    expect(() => PaperEngine.generate(bank, {1: 11}), throwsStateError);
  });
}
