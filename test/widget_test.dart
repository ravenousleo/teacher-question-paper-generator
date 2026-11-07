import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_question_paper_generator/main.dart';

void main() {
  testWidgets('Teacher Question Paper Generator launches',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TeacherPaperApp());

    expect(
      find.text('Teacher Question Paper Generator'),
      findsOneWidget,
    );
  });
}
