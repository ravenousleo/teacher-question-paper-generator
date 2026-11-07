import 'dart:math';
import '../models/app_models.dart';

class PaperEngine {
  static List<BankQuestion> generate(
      List<BankQuestion> bank, Map<int, int> counts,
      {Set<String> excluded = const {}, Random? random}) {
    final rng = random ?? Random();
    final selected = <BankQuestion>[];
    for (final entry in counts.entries) {
      if (entry.value < 0)
        throw ArgumentError('Question count cannot be negative.');
      final pool = bank
          .where((q) => q.marks == entry.key && !excluded.contains(q.id))
          .toList()
        ..shuffle(rng);
      if (entry.value > pool.length)
        throw StateError(
            'Only ${pool.length} unused ${entry.key}-mark questions are available; ${entry.value} requested.');
      selected.addAll(pool.take(entry.value));
    }
    selected.shuffle(rng);
    return selected;
  }

  static int totalMarks(Iterable<BankQuestion> questions) =>
      questions.fold(0, (s, q) => s + q.marks);
}
