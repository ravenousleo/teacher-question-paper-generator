import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'models/app_models.dart';
import 'services/question_parser.dart';
import 'services/local_store.dart';
import 'services/paper_engine.dart';
import 'services/export_service.dart';

void main() => runApp(const TeacherPaperApp());

class TeacherPaperApp extends StatelessWidget {
  const TeacherPaperApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Teacher Question Paper Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315C8C)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F7FA),
          cardTheme: const CardThemeData(
              elevation: 0, color: Colors.white, margin: EdgeInsets.zero)),
      home: const HomeScreen());
}

typedef MyApp = TeacherPaperApp;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final store = LocalStore();
  List<QuestionBank> banks = [];
  List<PaperRecord> papers = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await store.banks();
    final p = await store.papers();
    if (mounted)
      setState(() {
        banks = b;
        papers = p;
        loading = false;
      });
  }

  Future<void> _newPaper() async {
    final details = await Navigator.push<ExamDetails>(
        context, MaterialPageRoute(builder: (_) => const ExamSetupScreen()));
    if (details == null || !mounted) return;
    final result = await Navigator.push<PaperRecord>(
        context,
        MaterialPageRoute(
            builder: (_) =>
                BankAndBuildScreen(details: details, store: store)));
    if (result != null) {
      await store.savePaper(result);
      await _load();
      if (mounted)
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PreviewScreen(record: result, store: store)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
          title: const Text('Teacher Question Paper Generator'),
          centerTitle: false),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEAF1F8),
                            borderRadius: BorderRadius.circular(20)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  'Prepare question papers with confidence',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              const Text(
                                  'Import your existing Word question banks, select questions automatically or manually, and export a clean examination paper.'),
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                  onPressed: _newPaper,
                                  icon: const Icon(Icons.add),
                                  label:
                                      const Text('Create New Question Paper'))
                            ])),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                          child: _statCard('Question banks', '${banks.length}',
                              Icons.library_books)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard('Saved papers', '${papers.length}',
                              Icons.description))
                    ]),
                    const SizedBox(height: 24),
                    const Text('My Question Banks',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (banks.isEmpty)
                      const _EmptyCard(
                          text: 'Your saved question banks will appear here.')
                    else
                      ...banks.map((b) => Card(
                          child: ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(Icons.folder_outlined)),
                              title: Text(b.name),
                              subtitle: Text(
                                  '${b.questions.length} questions • ${b.questions.map((q) => q.marks).toSet().length} mark categories'),
                              trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final yes = await _confirm(
                                        context, 'Delete this question bank?');
                                    if (yes) {
                                      await store.deleteBank(b.id);
                                      _load();
                                    }
                                  })))),
                    const SizedBox(height: 24),
                    const Text('Previously Generated Papers',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (papers.isEmpty)
                      const _EmptyCard(
                          text: 'Your generated papers will appear here.')
                    else
                      ...papers.take(10).map((p) => Card(
                          child: ListTile(
                              leading: const CircleAvatar(
                                  child: Icon(Icons.article_outlined)),
                              title: Text(p.title),
                              subtitle: Text(
                                  '${p.questions.length} questions • ${p.totalMarks} marks • ${p.createdAt}'),
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => PreviewScreen(
                                          record: p, store: store))))))
                  ]))));
  Widget _statCard(String label, String value, IconData icon) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey.shade700))
            ])
          ])));
}

class ExamSetupScreen extends StatefulWidget {
  const ExamSetupScreen({super.key});
  @override
  State<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  final subject = TextEditingController(),
      otherStandard = TextEditingController(),
      otherBoard = TextEditingController(),
      otherExam = TextEditingController(),
      school = TextEditingController(),
      academicYear = TextEditingController(),
      duration = TextEditingController(text: '2 Hours');
  String standard = '10th Standard',
      board = 'State Board',
      exam = 'Model Examination';
  DateTime? date;
  final standards = [
    '5th Standard',
    '6th Standard',
    '7th Standard',
    '8th Standard',
    '9th Standard',
    '10th Standard',
    '11th Standard',
    '12th Standard',
    'Others'
  ];
  final boards = ['Matriculation', 'State Board', 'CBSE', 'ICSE', 'Others'];
  final exams = [
    'Class Test',
    'Unit Test',
    'Quarterly Examination',
    'Half-Yearly Examination',
    'Annual Examination',
    'Model Examination',
    'Others'
  ];
  bool get valid =>
      subject.text.trim().isNotEmpty &&
      date != null &&
      (standard != 'Others' || otherStandard.text.trim().isNotEmpty) &&
      (board != 'Others' || otherBoard.text.trim().isNotEmpty) &&
      (exam != 'Others' || otherExam.text.trim().isNotEmpty);
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('1. Examination Details')),
      body: Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: ListView(padding: const EdgeInsets.all(20), children: [
                const Text('Start with the examination details',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Fields marked as required must be completed.'),
                const SizedBox(height: 20),
                _drop('Standard', standard, standards,
                    (v) => setState(() => standard = v!)),
                if (standard == 'Others')
                  _field(otherStandard, 'Enter standard'),
                const SizedBox(height: 14),
                _drop('Education Board', board, boards,
                    (v) => setState(() => board = v!)),
                if (board == 'Others') _field(otherBoard, 'Enter board'),
                const SizedBox(height: 14),
                _field(subject, 'Subject name'),
                const SizedBox(height: 14),
                _drop('Examination Name', exam, exams,
                    (v) => setState(() => exam = v!)),
                if (exam == 'Others')
                  _field(otherExam, 'Enter examination name'),
                const SizedBox(height: 14),
                _field(school, 'School / institute name (optional)'),
                const SizedBox(height: 14),
                _field(academicYear, 'Academic year (optional)'),
                const SizedBox(height: 14),
                _field(duration, 'Duration (e.g. 2 Hours)'),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                          initialDate: DateTime.now());
                      if (d != null) setState(() => date = d);
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(date == null
                        ? 'Select examination date'
                        : '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}')),
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: valid
                        ? () => Navigator.pop(
                            context,
                            ExamDetails(
                                standard: standard == 'Others'
                                    ? otherStandard.text
                                    : standard,
                                board:
                                    board == 'Others' ? otherBoard.text : board,
                                subject: subject.text.trim(),
                                examName:
                                    exam == 'Others' ? otherExam.text : exam,
                                examDate:
                                    date!.toIso8601String().split('T').first,
                                schoolName: school.text.trim(),
                                academicYear: academicYear.text.trim(),
                                duration: duration.text.trim().isEmpty
                                    ? '2 Hours'
                                    : duration.text.trim()))
                        : null,
                    child: const Text('Next: Question Bank'))
              ]))));
  Widget _drop(String label, String value, List<String> options,
          ValueChanged<String?> onChanged) =>
      DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged);
  Widget _field(TextEditingController c, String hint) => TextField(
      controller: c,
      onChanged: (_) => setState(() {}),
      decoration:
          InputDecoration(labelText: hint, border: const OutlineInputBorder()));
}

class BankAndBuildScreen extends StatefulWidget {
  const BankAndBuildScreen(
      {super.key, required this.details, required this.store});
  final ExamDetails details;
  final LocalStore store;
  @override
  State<BankAndBuildScreen> createState() => _BankAndBuildScreenState();
}

class _BankAndBuildScreenState extends State<BankAndBuildScreen> {
  final uuid = const Uuid();
  List<BankQuestion> questions = [];
  List<PlatformFile> selectedFiles = [];
  bool busy = false;
  String currentBankId = 'active';
  String bankName = 'My Question Bank';
  final bankNameCtrl = TextEditingController(text: 'My Question Bank');
  final Map<int, TextEditingController> counts = {
    for (final m in [1, 2, 3, 5, 10]) m: TextEditingController(text: '0')
  };
  bool avoidUsed = false;
  Map<int, int> get requested => {
        for (final e in counts.entries) e.key: (int.tryParse(e.value.text) ?? 0)
      };
  int get requestedMarks =>
      requested.entries.fold(0, (s, e) => s + e.key * e.value);
  Future<void> _loadSavedBank() async {
    final all = await widget.store.banks();
    if (all.isEmpty) {
      _message('No saved question banks found.');
      return;
    }
    if (!mounted) return;
    final picked = await showDialog<QuestionBank>(
        context: context,
        builder: (ctx) => SimpleDialog(
            title: const Text('Choose a question bank'),
            children: all
                .map((b) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, b),
                    child: Text('${b.name} (${b.questions.length} questions)')))
                .toList()));
    if (picked != null)
      setState(() {
        questions = List.of(picked.questions);
        currentBankId = picked.id;
        bankNameCtrl.text = picked.name;
        selectedFiles = [];
        for (final m in questions.map((q) => q.marks).toSet())
          counts.putIfAbsent(m, () => TextEditingController(text: '0'));
      });
  }

  Future<void> _upload() async {
    if (selectedFiles.length >= 5) {
      _message('You can upload a maximum of five Word documents.');
      return;
    }
    final pick = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx'],
        withData: true,
        allowMultiple: false);
    if (pick == null || pick.files.isEmpty) return;
    final file = pick.files.first;
    if (file.bytes == null) {
      _message('The selected file could not be read.');
      return;
    }
    final marks = await _chooseMarks();
    if (marks == null) return;
    setState(() => busy = true);
    try {
      final parsed = QuestionParser.parseDocx(file.bytes!, marks,
          idPrefix: uuid.v4().substring(0, 6));
      setState(() {
        if (selectedFiles.isEmpty && questions.isEmpty)
          currentBankId = uuid.v4();
        questions.addAll(parsed);
        selectedFiles.add(file);
        counts.putIfAbsent(marks, () => TextEditingController(text: '0'));
      });
      _message(
          'Imported ${parsed.length} questions. Please review flagged items.');
    } catch (e) {
      _message('Could not read this DOCX: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<int?> _chooseMarks() async {
    int value = 1;
    final custom = TextEditingController();
    return showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Assign marks per question'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<int>(
                      value: 1,
                      items: [1, 2, 3, 5, 10]
                          .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m Mark${m == 1 ? '' : 's'}')))
                          .toList(),
                      onChanged: (v) => value = v ?? 1),
                  TextField(
                      controller: custom,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Or enter custom marks (optional)'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx, int.tryParse(custom.text) ?? value);
                      },
                      child: const Text('Import'))
                ]));
  }

  Future<void> _generate(bool manual) async {
    if (questions.isEmpty) {
      _message('Upload at least one question bank first.');
      return;
    }
    List<BankQuestion> chosen = [];
    if (manual) {
      final selected = await Navigator.push<List<BankQuestion>>(
          context,
          MaterialPageRoute(
              builder: (_) => ManualSelectScreen(questions: questions)));
      if (selected == null) return;
      chosen = selected;
    } else {
      final total = requested.values.fold(0, (a, b) => a + b);
      if (total == 0) {
        _message(
            'Enter the number of questions required in at least one category.');
        return;
      }
      final bankId = currentBankId;
      final excluded =
          avoidUsed ? await widget.store.usedQuestionIds(bankId) : <String>{};
      try {
        chosen = PaperEngine.generate(questions, requested, excluded: excluded);
      } catch (e) {
        _message(e.toString());
        return;
      }
    }
    if (chosen.isEmpty) {
      _message('No questions selected.');
      return;
    }
    final bank = QuestionBank(
        id: currentBankId,
        name: bankNameCtrl.text.trim().isEmpty
            ? 'My Question Bank'
            : bankNameCtrl.text.trim(),
        questions: questions,
        createdAt: DateTime.now().toIso8601String());
    await widget.store.saveBank(bank);
    if (avoidUsed && !manual)
      await widget.store
          .addUsedQuestionIds(currentBankId, chosen.map((q) => q.id));
    final record = PaperRecord(
        id: uuid.v4(),
        title: '${widget.details.examName} – ${widget.details.subject}',
        details: widget.details,
        questions: chosen,
        createdAt: DateTime.now().toString().substring(0, 16));
    if (mounted) Navigator.pop(context, record);
  }

  void _message(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  @override
  Widget build(BuildContext context) {
    final categories = questions.map((q) => q.marks).toSet().toList()..sort();
    return Scaffold(
        appBar: AppBar(title: const Text('2. Question Bank & Paper Setup')),
        body: Center(
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  _section('Question bank upload',
                      'Upload up to five .docx files. The files are processed on this device.'),
                  OutlinedButton.icon(
                      onPressed: _loadSavedBank,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Load a saved question bank')),
                  TextField(
                      controller: bankNameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Question bank name',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                      onPressed: busy ? null : _upload,
                      icon: const Icon(Icons.upload_file),
                      label: Text(busy
                          ? 'Processing…'
                          : 'Upload Word document (.docx)')),
                  if (selectedFiles.isNotEmpty)
                    ...selectedFiles.map((f) => ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(f.name),
                        subtitle: Text(
                            '${questions.length} questions currently imported'),
                        trailing: const Icon(Icons.check_circle,
                            color: Colors.green))),
                  const SizedBox(height: 8),
                  if (busy) const LinearProgressIndicator(),
                  if (questions.isNotEmpty) ...[
                    Text('${questions.length} questions detected',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...categories.map((m) => Card(
                        child: ListTile(
                            title: Text('$m Mark Questions'),
                            trailing: Text(
                                '${questions.where((q) => q.marks == m).length} available')))),
                    TextButton.icon(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => QuestionReviewScreen(
                                    questions: questions,
                                    onChanged: (q) =>
                                        setState(() => questions = q)))),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Review / edit imported questions'))
                  ],
                  const Divider(height: 32),
                  _section('Automatic paper generation',
                      'Set the number of questions required from each mark category.'),
                  ...(questions
                          .map((q) => q.marks)
                          .toSet()
                          .union({1, 2, 3, 5, 10}).toList()
                        ..sort())
                      .map((m) => Row(children: [
                            Expanded(child: Text('$m Mark questions')),
                            SizedBox(
                                width: 110,
                                child: TextField(
                                    controller: counts[m],
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                        isDense: true,
                                        border: OutlineInputBorder()))),
                            const SizedBox(width: 12),
                            SizedBox(
                                width: 95,
                                child: Text(
                                    '= ${m * (int.tryParse(counts[m]!.text) ?? 0)} marks'))
                          ])),
                  const SizedBox(height: 8),
                  Text('Requested total: $requestedMarks marks',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  CheckboxListTile(
                      value: avoidUsed,
                      onChanged: (v) => setState(() => avoidUsed = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                          'Avoid questions used in previous generated papers'),
                      subtitle: const Text(
                          'Applies to this saved question bank on this device.'),
                      controlAffinity: ListTileControlAffinity.leading),
                  FilledButton.icon(
                      onPressed: () => _generate(false),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate Random Paper')),
                  const Divider(height: 32),
                  _section('Manual paper preparation',
                      'Choose exactly which questions to include.'),
                  OutlinedButton.icon(
                      onPressed: () => _generate(true),
                      icon: const Icon(Icons.checklist),
                      label: const Text('Select Questions Manually'))
                ]))));
  }

  Widget _section(String title, String sub) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(color: Colors.grey.shade700))
      ]));
}

class ManualSelectScreen extends StatefulWidget {
  const ManualSelectScreen({super.key, required this.questions});
  final List<BankQuestion> questions;
  @override
  State<ManualSelectScreen> createState() => _ManualSelectScreenState();
}

class _ManualSelectScreenState extends State<ManualSelectScreen> {
  final selected = <String>{};
  String search = '';
  int? filter;
  Future<void> _finish() async {
    final chosen =
        widget.questions.where((q) => selected.contains(q.id)).toList();
    final ordered = await Navigator.push<List<BankQuestion>>(
        context,
        MaterialPageRoute(
            builder: (_) => ReorderSelectedScreen(questions: chosen)));
    if (ordered != null && mounted) Navigator.pop(context, ordered);
  }

  @override
  Widget build(BuildContext context) {
    final marks = widget.questions.map((q) => q.marks).toSet().toList()..sort();
    final visible = widget.questions
        .where((q) =>
            (filter == null || q.marks == filter) &&
            q.text.toLowerCase().contains(search.toLowerCase()))
        .toList();
    final chosen =
        widget.questions.where((q) => selected.contains(q.id)).toList();
    return Scaffold(
        appBar: AppBar(title: const Text('Manual Question Selection')),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search questions',
                        border: OutlineInputBorder()),
                    onChanged: (v) => setState(() => search = v)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                    value: filter,
                    decoration: const InputDecoration(
                        labelText: 'Filter by marks',
                        border: OutlineInputBorder()),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('All categories')),
                      ...marks.map((m) => DropdownMenuItem<int?>(
                          value: m, child: Text('$m marks')))
                    ],
                    onChanged: (v) => setState(() => filter = v))
              ])),
          Expanded(
              child: ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (c, i) {
                    final q = visible[i];
                    return CheckboxListTile(
                        value: selected.contains(q.id),
                        onChanged: (v) => setState(() {
                              if (v == true)
                                selected.add(q.id);
                              else
                                selected.remove(q.id);
                            }),
                        title: Text(q.text),
                        subtitle: Text(
                            '${q.marks} marks${q.review ? ' • Review flagged' : ''}'),
                        controlAffinity: ListTileControlAffinity.leading);
                  })),
          SafeArea(
              child: Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(children: [
                    Expanded(
                        child: Text(
                            '${chosen.length} selected • ${PaperEngine.totalMarks(chosen)} marks',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                    FilledButton(
                        onPressed: chosen.isEmpty ? null : _finish,
                        child: const Text('Review order'))
                  ])))
        ]));
  }
}

class ReorderSelectedScreen extends StatefulWidget {
  const ReorderSelectedScreen({super.key, required this.questions});
  final List<BankQuestion> questions;

  @override
  State<ReorderSelectedScreen> createState() => _ReorderSelectedScreenState();
}

class _ReorderSelectedScreenState extends State<ReorderSelectedScreen> {
  late List<BankQuestion> items;

  @override
  void initState() {
    super.initState();
    items = List.of(widget.questions);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrange Question Order'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, items),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final question = items[index];
          return Card(
            key: ValueKey(question.id),
            child: ListTile(
              leading: Text('${index + 1}.'),
              title: Text(question.text),
              subtitle: Text('${question.marks} marks'),
              trailing: const Icon(Icons.drag_handle),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final question = items.removeAt(oldIndex);
            items.insert(newIndex, question);
          });
        },
      ),
    );
  }
}

class QuestionReviewScreen extends StatefulWidget {
  const QuestionReviewScreen({
    super.key,
    required this.questions,
    required this.onChanged,
  });

  final List<BankQuestion> questions;
  final ValueChanged<List<BankQuestion>> onChanged;

  @override
  State<QuestionReviewScreen> createState() => _QuestionReviewScreenState();
}

class _QuestionReviewScreenState extends State<QuestionReviewScreen> {
  late List<BankQuestion> items;

  @override
  void initState() {
    super.initState();
    items = List.of(widget.questions);
  }

  Future<void> _editQuestion(BankQuestion question) async {
    final controller = TextEditingController(text: question.text);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit question'),
        content: TextField(controller: controller, maxLines: 5),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null && mounted) {
      setState(() => question.text = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Imported Questions'),
        actions: [
          TextButton(
            onPressed: () {
              widget.onChanged(items);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final question = items[index];
          return Card(
            key: ValueKey(question.id),
            child: ListTile(
              leading: Text('${index + 1}.'),
              title: Text(question.text),
              subtitle: Text(
                '${question.marks} marks${question.review ? ' • Please verify boundary' : ''}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editQuestion(question),
              ),
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final question = items.removeAt(oldIndex);
            items.insert(newIndex, question);
          });
        },
      ),
    );
  }
}

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.record, required this.store});
  final PaperRecord record;
  final LocalStore store;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late PaperRecord record;

  @override
  void initState() {
    super.initState();
    record = widget.record;
  }

  Future<void> _pdf() async {
    final bytes = await ExportService.pdf(record.details, record.questions);
    await Printing.sharePdf(bytes: bytes, filename: 'question_paper.pdf');
  }

  Future<void> _docx() async {
    final bytes = ExportService.docx(record.details, record.questions);
    await FilePicker.platform.saveFile(
      fileName: 'question_paper.docx',
      bytes: bytes,
    );
  }

  Future<void> _editDetails() async {
    final school = TextEditingController(text: record.details.schoolName);
    final year = TextEditingController(text: record.details.academicYear);
    final duration = TextEditingController(text: record.details.duration);
    final instructions =
        TextEditingController(text: record.details.instructions);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit paper details'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: school,
                    decoration: const InputDecoration(
                        labelText: 'School / institute name')),
                TextField(
                    controller: year,
                    decoration:
                        const InputDecoration(labelText: 'Academic year')),
                TextField(
                    controller: duration,
                    decoration: const InputDecoration(labelText: 'Duration')),
                TextField(
                    controller: instructions,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Instructions')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (ok == true) {
      setState(() {
        record.details.schoolName = school.text;
        record.details.academicYear = year.text;
        record.details.duration = duration.text;
        record.details.instructions = instructions.text;
      });
      await widget.store.savePaper(record);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<BankQuestion>>{};
    for (final question in record.questions) {
      grouped.putIfAbsent(question.marks, () => []).add(question);
    }
    final sortedMarks = grouped.keys.toList()..sort();
    var questionNo = 1;

    final paperContent = <Widget>[
      Text(
        record.details.schoolName.isEmpty
            ? 'SCHOOL / INSTITUTE NAME'
            : record.details.schoolName,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 5),
      Text(record.details.examName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      Text(
          '${record.details.standard}  |  ${record.details.subject}  |  ${record.details.board}',
          textAlign: TextAlign.center),
      if (record.details.academicYear.isNotEmpty)
        Text('Academic Year: ${record.details.academicYear}',
            textAlign: TextAlign.center),
      const Divider(height: 28),
      Text(
          'Date: ${record.details.examDate}    Duration: ${record.details.duration}    Maximum Marks: ${record.totalMarks}'),
      const SizedBox(height: 16),
      const Text('Instructions', style: TextStyle(fontWeight: FontWeight.bold)),
      Text(record.details.instructions),
      const SizedBox(height: 18),
    ];

    for (var sectionIndex = 0;
        sectionIndex < sortedMarks.length;
        sectionIndex++) {
      final mark = sortedMarks[sectionIndex];
      paperContent.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Section ${String.fromCharCode(65 + sectionIndex)} – $mark Mark Questions',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...grouped[mark]!.map((question) {
              final number = questionNo++;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text('$number. ${question.text}')),
                    Text('[${question.marks}]'),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('4. Question Paper Preview'),
        actions: [
          IconButton(
              tooltip: 'Edit paper details',
              onPressed: _editDetails,
              icon: const Icon(Icons.edit)),
          IconButton(
              tooltip: 'Export PDF',
              onPressed: _pdf,
              icon: const Icon(Icons.picture_as_pdf)),
          IconButton(
              tooltip: 'Export Word',
              onPressed: _docx,
              icon: const Icon(Icons.description)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: paperContent),
              )),
              const SizedBox(height: 12),
              const Text('Export options',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              FilledButton.icon(
                  onPressed: _pdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Share / Save PDF')),
              OutlinedButton.icon(
                  onPressed: _docx,
                  icon: const Icon(Icons.description),
                  label: const Text('Share / Save Word document')),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(text, style: TextStyle(color: Colors.grey.shade700))));
}

Future<bool> _confirm(BuildContext context, String message) async =>
    await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(content: Text(message), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'))
            ])) ??
    false;
