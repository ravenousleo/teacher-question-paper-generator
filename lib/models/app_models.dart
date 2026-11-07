import 'dart:convert';

class ExamDetails {
  ExamDetails({
    required this.standard,
    required this.board,
    required this.subject,
    required this.examName,
    required this.examDate,
    this.academicYear = '',
    this.duration = '2 Hours',
    this.schoolName = '',
    this.instructions = 'Answer all questions.\nWrite your answers neatly.',
  });

  String standard;
  String board;
  String subject;
  String examName;
  String examDate;
  String academicYear;
  String duration;
  String schoolName;
  String instructions;

  Map<String, dynamic> toJson() => {
        'standard': standard,
        'board': board,
        'subject': subject,
        'examName': examName,
        'examDate': examDate,
        'academicYear': academicYear,
        'duration': duration,
        'schoolName': schoolName,
        'instructions': instructions,
      };

  factory ExamDetails.fromJson(Map<String, dynamic> json) => ExamDetails(
        standard: json['standard'] as String? ?? '',
        board: json['board'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        examName: json['examName'] as String? ?? '',
        examDate: json['examDate'] as String? ?? '',
        academicYear: json['academicYear'] as String? ?? '',
        duration: json['duration'] as String? ?? '2 Hours',
        schoolName: json['schoolName'] as String? ?? '',
        instructions: json['instructions'] as String? ??
            'Answer all questions.\nWrite your answers neatly.',
      );
}

class BankQuestion {
  BankQuestion({
    required this.id,
    required this.text,
    required this.marks,
    this.sourceNumber = '',
    this.review = false,
  });

  String id;
  String text;
  String sourceNumber;
  int marks;
  bool review;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'marks': marks,
        'sourceNumber': sourceNumber,
        'review': review,
      };

  factory BankQuestion.fromJson(Map<String, dynamic> json) => BankQuestion(
        id: json['id'] as String? ?? '',
        text: json['text'] as String? ?? '',
        marks: (json['marks'] as num?)?.toInt() ?? 1,
        sourceNumber: json['sourceNumber'] as String? ?? '',
        review: json['review'] as bool? ?? false,
      );
}

class QuestionBank {
  QuestionBank({
    required this.id,
    required this.name,
    required this.questions,
    this.createdAt = '',
  });

  String id;
  String name;
  String createdAt;
  List<BankQuestion> questions;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt,
        'questions': questions.map((question) => question.toJson()).toList(),
      };

  factory QuestionBank.fromJson(Map<String, dynamic> json) => QuestionBank(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((item) => BankQuestion.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(),
      );
}

class PaperRecord {
  PaperRecord({
    required this.id,
    required this.title,
    required this.details,
    required this.questions,
    required this.createdAt,
  });

  String id;
  String title;
  String createdAt;
  ExamDetails details;
  List<BankQuestion> questions;

  int get totalMarks =>
      questions.fold(0, (total, question) => total + question.marks);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt,
        'details': details.toJson(),
        'questions': questions.map((question) => question.toJson()).toList(),
      };

  factory PaperRecord.fromJson(Map<String, dynamic> json) => PaperRecord(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
        details: ExamDetails.fromJson(
          Map<String, dynamic>.from(json['details'] as Map),
        ),
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((item) => BankQuestion.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList(),
      );
}

String encodeList<T>(
  List<T> items,
  Map<String, dynamic> Function(T) toJson,
) =>
    jsonEncode(items.map(toJson).toList());
