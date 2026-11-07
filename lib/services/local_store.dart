import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

import '../models/app_models.dart';

/// Sembast uses IndexedDB in Chrome and a local database file on Android.
class LocalStore {
  Future<Database>? _opening;
  Future<Database> _database() => _opening ??= _open();
  Future<Database> _open() async {
    if (kIsWeb) {
      return databaseFactoryWeb.openDatabase('teacher_question_paper.db');
    }
    final dir = await getApplicationDocumentsDirectory();
    return databaseFactoryIo.openDatabase(
      '${dir.path}/teacher_question_paper.db',
    );
  }

  final _banks = stringMapStoreFactory.store('question_banks');
  final _papers = stringMapStoreFactory.store('papers');
  final _used = stringMapStoreFactory.store('used_questions');
  Future<List<QuestionBank>> banks() async {
    final db = await _database();
    final rows = await _banks.find(db);
    return rows.map((r) => QuestionBank.fromJson(r.value)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveBank(QuestionBank bank) async {
    final db = await _database();
    await _banks.record(bank.id).put(db, bank.toJson());
  }

  Future<void> deleteBank(String id) async {
    final db = await _database();
    await _banks.record(id).delete(db);
  }

  Future<List<PaperRecord>> papers() async {
    final db = await _database();
    final rows = await _papers.find(db);
    return rows.map((r) => PaperRecord.fromJson(r.value)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> savePaper(PaperRecord paper) async {
    final db = await _database();
    await _papers.record(paper.id).put(db, paper.toJson());
  }

  Future<Set<String>> usedQuestionIds(String bankId) async {
    final db = await _database();
    final row = await _used.record(bankId).get(db);
    return Set<String>.from((row?['ids'] as List?) ?? const []);
  }

  Future<void> addUsedQuestionIds(String bankId, Iterable<String> ids) async {
    final db = await _database();
    final current = await usedQuestionIds(bankId);
    current.addAll(ids);
    await _used.record(bankId).put(db, {'ids': current.toList()});
  }
}
