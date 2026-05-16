import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:http/http.dart' as http;
import 'gemini_service.dart';
import 'quiz_screen.dart';

// ================== COMPILE (JUDGE0 CE) =====================
Future<String> realCompile(String lang, String code) async {
  final langIds = {
    'Python':     71,
    'JavaScript': 63,
    'TypeScript': 74,
    'Java':       62,
    'C/C++':      54,
    'PHP':        68,
  };
  final langId = langIds[lang];
  if (langId == null) {
    return 'Ngon ngu "$lang" chua ho tro compile.\nHo tro: ${langIds.keys.join(", ")}';
  }
  final encoded = base64Encode(utf8.encode(code));
  try {
    final submit = await http.post(
      Uri.parse('https://ce.judge0.com/submissions?base64_encoded=true&wait=false'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'source_code': encoded,
        'language_id': langId,
        'stdin': '',
      }),
    ).timeout(const Duration(seconds: 15));
    if (submit.statusCode != 201) return 'Judge0 loi ${submit.statusCode}: ${submit.body}';
    final token = jsonDecode(submit.body)['token'] as String?;
    if (token == null) return 'Khong lay duoc token tu Judge0.';
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 1500));
      final result = await http.get(
        Uri.parse('https://ce.judge0.com/submissions/$token?base64_encoded=true&fields=stdout,stderr,compile_output,status,message'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (result.statusCode != 200) continue;
      final data = jsonDecode(result.body) as Map<String, dynamic>;
      final statusId = data['status']?['id'] as int?;
      if (statusId == 1 || statusId == 2) continue; // In Queue, Processing
      final stdout = _decodeBase64Safe(data['stdout']);
      final stderr = _decodeBase64Safe(data['stderr']);
      final compileOutput = _decodeBase64Safe(data['compile_output']);
      final statusDesc = data['status']?['description'] ?? '';
      final buffer = StringBuffer();
      if (compileOutput.isNotEmpty) buffer.writeln('Loi bien dich:\n$compileOutput');
      if (stdout.isNotEmpty) buffer.writeln(stdout);
      if (stderr.isNotEmpty) buffer.writeln('Stderr:\n$stderr');
      if (stdout.isEmpty && stderr.isEmpty && compileOutput.isEmpty)
        buffer.writeln('(Chuong trinh khong co output)');
      if (statusId != 3) buffer.writeln('\nTrang thai: $statusDesc');
      return buffer.toString().trim();
    }
    return 'Timeout: Code chay qua 15 giay.';
  } on TimeoutException {
    return 'Timeout ket noi den Judge0 API.';
  } catch (e) {
    return 'Loi ket noi Judge0 API: $e';
  }
}
String _decodeBase64Safe(dynamic value) {
  if (value == null || value.toString().isEmpty) return '';
  try { return utf8.decode(base64Decode(value.toString())); }
  catch (_) { return value.toString(); }
}

// ================== GIẢ LẬP AI FIX ==========================
Future<Map<String, dynamic>> fakeAIFix(String lang, String code) async {
  await Future.delayed(const Duration(milliseconds: 1200));
  String fixed = code;
  String report = '';
  int errors = 0;
  final lines = code.split('\n');
  List<String> analysis = [];

  if (lang == 'Python') {
    List<String> fixedLines = List<String>.from(lines);
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (l.trimLeft().startsWith('if ') && !l.trimRight().endsWith(':')) {
        analysis.add('Line ${i + 1}: if thieu dau :');
        errors++;
        fixedLines[i] = '${l.trimRight()}:';
      }
      if (l.trimLeft().startsWith('def ') && !l.trimRight().endsWith(':')) {
        analysis.add('Line ${i + 1}: def thieu dau :');
        errors++;
        fixedLines[i] = '${l.trimRight()}:';
      }
      if (fixedLines[i].trimRight().endsWith(';')) {
        analysis.add('Line ${i + 1}: Python khong co dau ; cuoi dong.');
        errors++;
        fixedLines[i] = fixedLines[i].replaceAll(RegExp(r';\s*$'), '');
      }
    }
    fixed = fixedLines.join('\n');
    report = errors > 0
        ? 'AI da fix hoac canh bao $errors loi Python pho bien.'
        : 'Khong thay loi pho bien.';
    if (errors == 0) fixed = code;
  } else if (lang == 'JavaScript' || lang == 'TypeScript') {
    List<String> fixedLines = List<String>.from(lines);
    for (int i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (l.contains('.map(') && l.contains('=> {') && !l.contains('return')) {
        analysis.add('Line ${i + 1}: Arrow function map nen co return.');
        errors++;
      }
      if (l.contains('var ')) {
        analysis.add('Line ${i + 1}: Nen dung const/let thay vi var.');
        errors++;
        fixedLines[i] = l.replaceAllMapped(RegExp(r'\bvar\s+(\w+)\s*='), (m) => 'const ${m[1]} =');
      }
    }
    fixed = fixedLines.join('\n');
    report = errors == 0
        ? 'Khong phat hien loi pho bien trong $lang.'
        : 'Da phat hien $errors van de tren.';
  } else {
    report = 'Chua ho tro AI fix cho $lang nay.';
  }

  return {
    'fixed': fixed,
    'report': report,
    'lineAnalysis': analysis,
    'errors': errors,
  };
}

// ====================== WIDGETS ============================
class CodevaraScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final Function(ThemeMode)? onThemeChanged;
  const CodevaraScreen({
    super.key,
    this.themeMode = ThemeMode.light,
    this.onThemeChanged,
  });
  @override
  State<CodevaraScreen> createState() => _CodevaraScreenState();
}

class _CodevaraScreenState extends State<CodevaraScreen>
    with TickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  String detectedLang = 'Chua nhan';
  bool _analyzing = false;
  bool _compiling = false;
  bool _aiChatLoading = false;
  int _errorCount = 0;

  String _aiChatReply = '';
  String _terminalOutput = '';
  String _analysisReport = '';
  String _fixedCode = '';
  List<String> _lineAnalysis = [];

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _codeController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Codevara AI'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          actions: [
            IconButton(
              icon: const Icon(Icons.wb_sunny, color: Colors.orange),
              onPressed: () => widget.onThemeChanged?.call(ThemeMode.light),
            )
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.code), text: 'Code'),
              Tab(icon: Icon(Icons.terminal), text: 'Terminal'),
              Tab(icon: Icon(Icons.chat), text: 'AI Chat'),
            ],
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
          ),
        ),
        backgroundColor: Colors.white,
        body: TabBarView(
          children: [
            buildCodeTab(),
            buildTerminalTab(),
            buildChatTab(),
          ],
        ),
      ),
    );
  }

  Widget buildCodeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: buildLineNumbers(_codeController.text),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    maxLines: null,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        color: Colors.black),
                    decoration: InputDecoration(
                      hintText: '// Dan code tai day',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('File'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _codeController.clear();
                  setState(() {
                    detectedLang = 'Chua nhan';
                    _fixedCode = '';
                    _analysisReport = '';
                    _lineAnalysis = [];
                    _errorCount = 0;
                    _terminalOutput = '';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  detectLanguage();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ngon ngu: $detectedLang')));
                },
                icon: const Icon(Icons.language),
                label: const Text('Detect'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              ElevatedButton.icon(
                onPressed: _analyzing ? null : handleAIFix,
                icon: _analyzing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_fix_high),
                label: const Text('AI Fix'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              ),
              ElevatedButton.icon(
                onPressed: _aiChatLoading ? null : generateQuiz,
                icon: const Icon(Icons.quiz),
                label: const Text("Tạo Quiz từ code"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_fixedCode.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Text('Errors fixed: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$_errorCount', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (detectedLang != 'Chua nhan')
                  Text(detectedLang, style: const TextStyle(color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 7),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Code da fix:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: buildLineNumbers(_fixedCode),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: HighlightView(
                        _fixedCode,
                        language: _getSyntaxLang(detectedLang),
                        theme: githubTheme,
                        padding: const EdgeInsets.all(8),
                        textStyle: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                            color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _fixedCode));
                    _showSnack('Da copy code!');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.content_paste),
                  label: const Text('Paste fixed'),
                  onPressed: () {
                    _codeController.text = _fixedCode;
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                  onPressed: () async {
                    final bytes = Uint8List.fromList(utf8.encode(_fixedCode));
                    await FileSaver.instance.saveAs(
                      name: 'fixed_code',
                      bytes: bytes,
                      ext: 'txt',
                      mimeType: MimeType.text,
                    );
                    _showSnack('Da export file fixed_code.txt');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget buildTerminalTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: _compiling ? null : handleCompile,
            icon: _compiling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow),
            label: Text(_compiling
                ? 'Dang chay...'
                : 'Chay code  ($detectedLang)  [Judge0 CE]'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Terminal / Compiler output:', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  _terminalOutput.isEmpty
                      ? '> Nhan "Chay code" de thuc thi.\n> Dam bao da dan code vao tab Code.'
                      : _terminalOutput,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: _terminalOutput.toLowerCase().contains('loi') ||
                            _terminalOutput.contains('Error')
                        ? Colors.orange[300]
                        : Colors.greenAccent,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_lineAnalysis.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('Line-by-line analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._lineAnalysis.map((x) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Text('- $x', style: const TextStyle(fontSize: 14, color: Colors.black87)),
              )),
          const SizedBox(height: 8),
        ],
        if (_analysisReport.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber),
              ),
              child: Text(_analysisReport,
                  style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black)),
            ),
          ),
        ],
      ],
    );
  }

  Widget buildChatTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _chatController,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              hintText: 'Vi du: Giai thich code tren, Tim bug trong code nay...',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              fillColor: Colors.white,
              filled: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ElevatedButton.icon(
            icon: _aiChatLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: Text(_aiChatLoading ? 'Dang hoi AI...' : 'Gui  [Gemini AI]'),
            onPressed: _aiChatLoading ? null : handleAIChat,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: _aiChatReply.isNotEmpty
                    ? Text(
                        _aiChatReply,
                        style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                      )
                    : const Text(
                        'Cau tra loi cua AI se xuat hien tai day.\n\n'
                        'Goi y:\n'
                        '- "Giai thich code tren"\n'
                        '- "Tim bug trong code nay"\n'
                        '- "Toi uu hieu nang"\n'
                        '- "Dich sang JavaScript"',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildLineNumbers(String code) {
    final lines = code.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(lines.length, (i) => Text('${i + 1}',
        style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5))),
    );
  }

  void detectLanguage() {
    final code = _codeController.text.trim().toLowerCase();
    String lang = 'Khac';
    if (RegExp(r'\bdef\b').hasMatch(code) ||
        code.contains('print(') ||
        (code.contains('import ') && code.contains(' as ')) ||
        (code.startsWith('class ') && code.contains(':'))) {
      lang = 'Python';
    } else if (code.contains('statelesswidget') ||
        code.contains('statefulwidget') ||
        code.contains('widget build(')) {
      lang = 'Dart/Flutter';
    } else if (RegExp(r'\bfunction\b').hasMatch(code) ||
        code.contains('console.log') ||
        code.contains('document.') ||
        RegExp(r'=>\s*{').hasMatch(code)) {
      lang = 'JavaScript';
      if (code.contains(': number') || code.contains(': string')) {
        lang = 'TypeScript';
      }
    } else if (RegExp(r'\bpublic\s+static\s+void\s+main').hasMatch(code) ||
        RegExp(r'system\.out\.println').hasMatch(code)) {
      lang = 'Java';
    } else if (code.contains('#include') ||
        (code.contains('int main(') && code.contains('{'))) {
      lang = 'C/C++';
    } else if (code.contains('<?php') || code.contains('echo ')) {
      lang = 'PHP';
    } else if (code.contains('select') && code.contains('from')) {
      lang = 'SQL';
    } else if (code.contains('<html') ||
        code.contains('<!doctype') ||
        code.contains('<button')) {
      lang = 'HTML/CSS';
    }
    setState(() => detectedLang = lang);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'txt', 'js', 'ts', 'py', 'sql', 'html',
          'css', 'dart', 'json', 'java', 'cpp', 'c', 'php'
        ],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _showSnack('Khong doc duoc file (bytes null).');
        return;
      }
      final content = utf8.decode(bytes, allowMalformed: true);
      _codeController.text = content;
      setState(() {});
      detectLanguage();
      _showSnack('Da tai file: ${file.name}  |  Ngon ngu: $detectedLang');
    } catch (e) {
      _showSnack('Loi chon file: $e');
    }
  }

  Future<void> handleCompile() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Hay dan code vao editor truoc!');
      return;
    }
    detectLanguage();
    setState(() {
      _compiling = true;
      _terminalOutput = 'Dang gui code len Judge0 CE...\nNgon ngu: $detectedLang';
    });
    final output = await realCompile(detectedLang, _codeController.text);
    setState(() {
      _terminalOutput = output;
      _compiling = false;
    });
  }

  Future<void> handleAIFix() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnack('Hay dan code vao editor truoc!');
      return;
    }
    detectLanguage();
    setState(() {
      _analyzing = true;
      _fixedCode = '';
      _lineAnalysis = [];
      _errorCount = 0;
    });
    final result = await fakeAIFix(detectedLang, _codeController.text);
    setState(() {
      final fixedRaw = result['fixed'] as String? ?? '';
      _fixedCode = fixedRaw.isEmpty ? _codeController.text : fixedRaw;
      _analysisReport = result['report'] as String? ?? '';
      _lineAnalysis = List<String>.from(result['lineAnalysis'] ?? []);
      _errorCount = result['errors'] as int? ?? 0;
      _analyzing = false;
    });
  }

  Future<void> handleAIChat() async {
    if (_chatController.text.trim().isEmpty) {
      _showSnack('Hay nhap cau hoi cho AI');
      return;
    }
    setState(() {
      _aiChatLoading = true;
      _aiChatReply = '';
    });
    try {
      detectLanguage();
      final prompt =
          'Ban la AI code assistant. Hay tra loi bang tieng Viet, ngan gon, logic, giai thich de hieu phu hop cho nguoi moi hoc.\n\n'
          'Ngon ngu code dang dung: $detectedLang\n\n'
          'Cau hoi:\n${_chatController.text}\n\n'
          'Code:\n```\n${_codeController.text.isEmpty ? "(Khong co code)" : _codeController.text}\n```\n\nTra loi:';
      final result = await GeminiService.askAI(prompt);
      setState(() => _aiChatReply = result);
    } catch (e) {
      setState(() => _aiChatReply = 'Loi AI: $e');
    }
    setState(() => _aiChatLoading = false);
  }

  Future<void> generateQuiz() async {
  final code = _codeController.text.trim();

  if (code.isEmpty) {
    _showSnack('Dán code trước!');
    return;
  }

  // Đảm bảo detectLanguage đã chạy trước nếu cần (hoặc chạy lại ở đây)
  detectLanguage();

  // Nhận biết ngôn ngữ (nếu bạn có nhiều ngôn ngữ)
  final lang = detectedLang;

  // FIX code trước khi quiz (luôn lấy mã đúng)
  final result = await fakeAIFix(lang, code);
  final fixedCode = result['fixed'] as String? ?? code;

  List<QuizQuestion> quizList = [];

  // for
  if (fixedCode.contains("for")) {
    quizList.addAll([
      QuizQuestion(
        question: "for dùng để làm gì?",
        code: fixedCode,
        options: ["Điều kiện", "Lặp", "Gán", "Gọi hàm"],
        correct: 1,
      ),
      QuizQuestion(
        question: "Cú pháp đúng của for trong Python là gì?",
        code: fixedCode,
        options: [
          "for i in range(5):",
          "for i in range(5);",
          "for (i=0;i<5;i++)",
          "foreach i in range(5)"
        ],
        correct: 0,
      ),
    ]);
  }
  // if
  else if (fixedCode.contains("if")) {
    quizList.addAll([
      QuizQuestion(
        question: "if dùng để làm gì?",
        code: fixedCode,
        options: ["Lặp", "Điều kiện", "Hàm", "Biến"],
        correct: 1,
      ),
      QuizQuestion(
        question: "Cú pháp đúng cho if là gì?",
        code: fixedCode,
        options: [
          "if x > 0:",
          "if x > 0 {}",
          "if (x > 0);",
          "if: x > 0"
        ],
        correct: 0,
      ),
    ]);
  }
  // def
  else if (fixedCode.contains("def ")) {
    quizList.addAll([
      QuizQuestion(
        question: "def trong Python dùng để làm gì?",
        code: fixedCode,
        options: ["Tạo biến", "Import", "Tạo hàm", "Tạo list"],
        correct: 2,
      ),
      QuizQuestion(
        question: "Cú pháp định nghĩa hàm Python đúng là?",
        code: fixedCode,
        options: [
          "def foo():",
          "def foo {}",
          "def foo;",
          "function foo():"
        ],
        correct: 0,
      ),
    ]);
  }
  // print
  else if (fixedCode.contains("print")) {
    quizList.addAll([
      QuizQuestion(
        question: "print() dùng để làm gì?",
        code: fixedCode,
        options: ["Nhập dữ liệu", "Xuất dữ liệu", "Xóa dữ liệu", "Tạo file"],
        correct: 1,
      ),
      QuizQuestion(
        question: "Dòng nào giúp in số 5?",
        code: fixedCode,
        options: [
          "print(5)",
          "output(5)",
          "echo 5",
          "display(5)"
        ],
        correct: 0,
      ),
    ]);
  }

  if (quizList.isEmpty) {
    _showSnack("Không phát hiện nội dung quiz nào phù hợp!");
    return;
  }

  SharedQuizData.codeQuizzes = quizList;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Đã tạo Quiz từ code"),
      content: const Text("Quiz đã được tạo! Bạn muốn làm luôn không?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Đóng"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuizPlayScreen(
                  topic: 'Quiz từ code',
                  customQuestions: SharedQuizData.codeQuizzes,
                ),
              ),
            );
          },
          child: const Text("Làm quiz"),
        ),
      ],
    ),
  );
}

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _getSyntaxLang(String lang) {
    switch (lang) {
      case 'Python':      return 'python';
      case 'JavaScript':  return 'javascript';
      case 'TypeScript':  return 'typescript';
      case 'HTML/CSS':    return 'html';
      case 'SQL':         return 'sql';
      case 'Dart/Flutter':return 'dart';
      case 'Java':        return 'java';
      case 'C/C++':       return 'cpp';
      case 'PHP':         return 'php';
      default:            return 'text';
    }
  }
}  