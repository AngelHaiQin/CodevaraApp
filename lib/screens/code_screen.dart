import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CodeScreen extends StatefulWidget {
  const CodeScreen({super.key});

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final TextEditingController _codeController = TextEditingController();

  String detectedLang = 'Chưa nhận';
  String aiScore = 'Chưa check';

  bool _analyzing = false;
  bool _checkingAI = false;

  String _analysisReport = '';
  String _fixedCode = '';

  // --- Detect "paste vs typing" (không cần #/Step) ---
  int _lastTextLen = 0;
  DateTime? _lastEditAt;
  double _pasteBoost = 0; // 0..40 điểm
  Timer? _pasteResetTimer;

  // --- Config: chỉ 2 trạng thái (AI hoặc Viết tay) ---
  // NOTE: để "bắt AI" mạnh hơn cho code ngắn (không cần comment),
  // ta dùng ngưỡng thấp hơn + thêm rule mạnh cho JS array methods.
  static const int _aiThreshold = 45;

  @override
  void initState() {
    super.initState();
    _lastTextLen = _codeController.text.length;
    _lastEditAt = DateTime.now();
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    final now = DateTime.now();
    final current = _codeController.text;
    final len = current.length;

    final prevLen = _lastTextLen;
    final delta = (len - prevLen).abs();

    final prevTime = _lastEditAt ?? now;
    final ms = now.difference(prevTime).inMilliseconds.clamp(1, 1 << 30);

    // Heuristic paste:
    // - delta lớn trong thời gian rất ngắn => paste/copy (thường gặp khi dùng AI/copy)
    if (delta >= 300 && ms <= 200) {
      _pasteBoost = (_pasteBoost + 40).clamp(0, 40);
    } else if (delta >= 120 && ms <= 80) {
      _pasteBoost = (_pasteBoost + 28).clamp(0, 40);
    } else if (delta >= 60 && ms <= 60) {
      _pasteBoost = (_pasteBoost + 14).clamp(0, 40);
    }

    // Nếu không paste thêm trong 4s thì giảm dần boost
    _pasteResetTimer?.cancel();
    _pasteResetTimer = Timer(const Duration(seconds: 4), () {
      _pasteBoost = (_pasteBoost - 10).clamp(0, 40);
    });

    _lastTextLen = len;
    _lastEditAt = now;
  }

  @override
  void dispose() {
    _pasteResetTimer?.cancel();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Codevara - Dán Code'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dán code hoặc chọn file để Codevara phân tích:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Input code
            TextField(
              controller: _codeController,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: '// Ví dụ: print("Hello") hoặc function() {}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: Colors.grey[100],
                filled: true,
              ),
            ),
            const SizedBox(height: 12),

            // Buttons row 1: pick file + clear
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.upload_file),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    label: const Text('Chọn File', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _codeController.clear();
                      setState(() {
                        detectedLang = 'Chưa nhận';
                        aiScore = 'Chưa check';
                        _analysisReport = '';
                        _fixedCode = '';
                      });

                      _pasteBoost = 0;
                      _lastTextLen = 0;
                      _lastEditAt = DateTime.now();
                    },
                    icon: const Icon(Icons.clear),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    label: const Text('Xoá', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Buttons row 2: detect + ai check
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: detectLanguage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Nhận Ngôn Ngữ', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkingAI ? null : checkAI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _checkingAI ? 'Đang check...' : 'Check AI',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Analyze & Fix
            ElevatedButton.icon(
              onPressed: _analyzing ? null : _analyzeAndFix,
              icon: _analyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_fix_high),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              label: Text(
                _analyzing ? 'Đang phân tích...' : 'Phân tích lỗi & Sửa (AI)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 20),

            // Result box 1: language + ai score
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kết quả Codevara:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Ngôn ngữ: $detectedLang', style: TextStyle(fontSize: 18, color: Colors.green[700])),
                  Text('AI Score: $aiScore', style: TextStyle(fontSize: 18, color: Colors.orange[700])),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Result box 2: analysis report
            if (_analysisReport.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI phân tích lỗi:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_analysisReport, style: const TextStyle(fontSize: 14, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Result box 3: fixed code
            if (_fixedCode.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Code gợi ý đã sửa:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _fixedCode,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        _codeController.text = _fixedCode;
                        setState(() {});
                      },
                      icon: const Icon(Icons.content_paste),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      label: const Text('Dán lại code đã sửa'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['txt', 'js', 'ts', 'py', 'sql', 'html', 'css', 'dart', 'json'],
        withData: true, // ✅ web/Chrome
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _showSnack('Không đọc được file (bytes null).');
        return;
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      _codeController.text = content;

      detectLanguage();
      _showSnack('Đã tải file: ${file.name}');
    } catch (e) {
      _showSnack('Lỗi chọn file: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void detectLanguage() {
    final code = _codeController.text.trim().toLowerCase();

    if (code.isEmpty) {
      setState(() => detectedLang = 'Dán code trước nhé!');
      return;
    }

    String lang;
    if (code.contains('function') || code.contains('console.log') || code.contains('document.')) {
      lang = 'JavaScript';
    } else if (code.contains('print(') || code.contains('def ') || code.contains('import ')) {
      lang = 'Python';
    } else if (code.contains('select') && code.contains('from')) {
      lang = 'SQL';
    } else if (code.contains('<html') || code.contains('<!doctype') || code.contains('<button')) {
      lang = 'HTML/CSS';
    } else if (code.contains('class ') && code.contains('widget') && code.contains('build(')) {
      lang = 'Dart/Flutter';
    } else {
      lang = 'Khác';
    }

    setState(() => detectedLang = lang);
  }

  /// ✅ Check AI (ép ra AI hoặc Viết tay)
  /// - Không cần comment
  /// - Bắt AI mạnh hơn cho code JS ngắn (map/filter/reduce / arrow / const pattern)
  Future<void> checkAI() async {
    if (_checkingAI) return;

    setState(() {
      _checkingAI = true;
      aiScore = 'Codevara đang kiểm tra AI...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 250));

      final code = _codeController.text.trim();
      if (code.isEmpty) {
        setState(() => aiScore = '⚠️ Bạn chưa dán code');
        return;
      }

      final lower = code.toLowerCase();
      final lines = code.split('\n');

      double score = 0;

      // 1) Paste boost (mạnh nhất)
      score += _pasteBoost; // 0..40

      // 2) Array methods (JS/TS) - tăng điểm ngay cả khi chỉ có 1 map
      final arrayMethodCount = RegExp(
        r'\.\s*(map|filter|reduce|forEach|find|some|every|flatMap)\s*\(',
        caseSensitive: false,
      ).allMatches(code).length;
      if (arrayMethodCount >= 3) score += 22;
      else if (arrayMethodCount == 2) score += 16;
      else if (arrayMethodCount == 1) score += 12; // ✅ quan trọng: 1 map cũng cộng khá

      // 3) Functional chain map/filter/reduce (tính riêng)
      final chainCount = RegExp(r'\.\s*(map|filter|reduce)\s*\(', caseSensitive: false).allMatches(code).length;
      if (chainCount >= 3) score += 10;
      else if (chainCount == 2) score += 6;

      // 4) Arrow functions
      final arrowCount = RegExp(r'=>').allMatches(code).length;
      if (arrowCount >= 2) score += 10;
      else if (arrowCount == 1) score += 6; // ✅ 1 arrow cũng cộng

      // 5) Nhiều khai báo biến (const/final/let)
      final declCount =
          RegExp(r'^\s*(const|final|let)\s+\w+\s*=', multiLine: true, caseSensitive: false).allMatches(code).length;
      if (declCount >= 4) score += 12;
      else if (declCount >= 2) score += 8;
      else if (declCount == 1) score += 3;

      // 6) Tên biến "sách vở"
      if (RegExp(r'\b(accumulator|inputArray|resultArray|payload|sanitize|sanitiz|normalize|transform|parameter)\b',
              caseSensitive: false)
          .hasMatch(code)) {
        score += 12;
      }

      // 7) Type hints (Python)
      if (RegExp(r'\b->\s*\w+', multiLine: true).hasMatch(code)) score += 14;
      if (RegExp(r'\b:\s*(int|str|bool|float|list|dict)\b', caseSensitive: false).hasMatch(code)) score += 10;

      // 8) Comment/docstring (nhẹ)
      final commentLines = lines.where((l) {
        final t = l.trimLeft();
        return t.startsWith('//') ||
            t.startsWith('#') ||
            t.startsWith('/*') ||
            t.startsWith('*') ||
            t.startsWith('"""') ||
            t.startsWith("'''");
      }).length;
      if (commentLines >= 4) score += 6;
      else if (commentLines >= 2) score += 3;

      // 9) Keywords (nhẹ)
      const keywords = ['expected', 'edge case', 'optimize', 'sanity check', 'verify', 'example'];
      for (final k in keywords) {
        if (lower.contains(k)) score += 3;
      }

      // 10) Viết tay: lỗi syntax phổ biến -> trừ (mạnh)
      if (_looksLikeHandWrittenMistake(code)) score -= 25;

      score = score.clamp(0, 100);

      // Ép 2 mức
      final isAi = score >= _aiThreshold;
      final verdict = isAi ? '⚠️ AI' : '✅ Viết tay';

      final aiPercent = score.round();
      final humanPercent = (100 - aiPercent).clamp(0, 100);

      setState(() {
        aiScore = '$verdict • AI: $aiPercent% • Viết tay: $humanPercent%';
      });
    } catch (e, st) {
      debugPrint('checkAI error: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() => aiScore = '❌ Lỗi khi check AI: $e');
    } finally {
      if (!mounted) return;
      setState(() => _checkingAI = false);
    }
  }

  bool _looksLikeHandWrittenMistake(String code) {
    final lower = code.toLowerCase();

    // Python: thiếu :
    if (RegExp(r'^\s*def\s+\w+\s*\(.*\)\s*$', multiLine: true).hasMatch(code)) return true;
    if (RegExp(r'^\s*(if|elif|else)\b(?!.*:)\s*.*$', multiLine: true).hasMatch(code) && lower.contains('def ')) {
      return true;
    }

    // JS: map thiếu return trong block
    if (RegExp(r'\.map\([^)]*=>\s*\{[^}]*\}', multiLine: true).hasMatch(code) && !code.contains('return')) {
      return true;
    }

    // HTML: thiếu đóng tag
    if (lower.contains('<div') && !lower.contains('</div>')) return true;

    // SQL: JOIN thiếu ON
    if (lower.contains(' join ') && !lower.contains(' on ')) return true;

    return false;
  }

  // --- giữ nguyên các hàm phân tích lỗi/sửa ---
  Future<void> _analyzeAndFix() async {
    final code = _codeController.text;
    if (code.trim().isEmpty) {
      _showSnack('Dán code hoặc chọn file trước.');
      return;
    }

    setState(() {
      _analyzing = true;
      _analysisReport = '';
      _fixedCode = '';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    final result = _ruleBasedAnalyze(detectedLang, code);

    if (!mounted) return;
    setState(() {
      _analysisReport = result.report;
      _fixedCode = result.fixedCode;
      _analyzing = false;
    });
  }

  _AnalysisResult _ruleBasedAnalyze(String lang, String code) {
    final lines = code.split('\n');

    final isJS = lang.contains('JavaScript') || code.contains('console.log') || code.contains('function ');
    final isPy = lang.contains('Python') || code.contains('def ') || code.contains('print(');
    final isSQL = lang.contains('SQL') || (code.toLowerCase().contains('select') && code.toLowerCase().contains('from'));
    final isDart = lang.contains('Dart') || (code.contains('class ') && code.contains('Widget'));

    final issues = <_Issue>[];
    final fixedLines = List<String>.from(lines);

    if (isJS) {
      for (int i = 0; i < lines.length; i++) {
        final l = lines[i];
        final hasMap = l.contains('.map(');
        final hasArrowBlock = l.contains('=> {') && l.contains('}');
        final missingReturn = hasArrowBlock && !l.contains('return');

        if (hasMap && hasArrowBlock && missingReturn) {
          issues.add(_Issue(
            line: i + 1,
            message: 'Arrow function dùng "{ }" nhưng thiếu "return" → map() sẽ ra undefined.',
            suggestion: 'Đổi sang: map(x => x*2) hoặc thêm "return".',
          ));
        }
      }

      return _buildResult(langName: 'JavaScript', original: code, fixedLines: fixedLines, issues: issues);
    }

    if (isPy) {
      for (int i = 0; i < lines.length; i++) {
        final l = lines[i].trimRight();
        if (l.trimLeft().startsWith('def ') && l.contains(')') && !l.trim().endsWith(':')) {
          issues.add(_Issue(
            line: i + 1,
            message: 'Thiếu dấu ":" ở cuối khai báo hàm (def ...:).',
            suggestion: 'Thêm ":" vào cuối dòng def.',
          ));
        }
      }

      for (int i = 0; i < lines.length; i++) {
        final t = lines[i].trimRight();
        final s = t.trimLeft();
        final isIfLike = (s.startsWith('if ') || s.startsWith('elif ') || s.startsWith('else')) &&
            !s.startsWith('else:') &&
            !s.endsWith(':');

        if (isIfLike) {
          issues.add(_Issue(
            line: i + 1,
            message: 'Thiếu dấu ":" ở cuối câu lệnh if/elif/else.',
            suggestion: 'Thêm ":" vào cuối dòng if/elif/else.',
          ));
        }
      }

      return _buildResult(langName: 'Python', original: code, fixedLines: fixedLines, issues: issues);
    }

    if (isSQL) {
      final lower = code.toLowerCase();
      if (lower.contains(' join ') && !lower.contains(' on ')) {
        issues.add(_Issue(
          line: _findLineNumber(lines, (l) => l.toLowerCase().contains('join')) ?? 1,
          message: 'JOIN thiếu điều kiện ON.',
          suggestion: 'Thêm: ON tableA.id = tableB.a_id (tuỳ schema).',
        ));
      }

      return _buildResult(langName: 'SQL', original: code, fixedLines: fixedLines, issues: issues);
    }

    if (isDart) {
      return _buildResult(langName: 'Dart/Flutter', original: code, fixedLines: fixedLines, issues: issues);
    }

    return _AnalysisResult(
      report: 'Chưa nhận diện được ngôn ngữ hoặc chưa có rule cho đoạn code này.',
      fixedCode: '',
    );
  }

  _AnalysisResult _buildResult({
    required String langName,
    required String original,
    required List<String> fixedLines,
    required List<_Issue> issues,
  }) {
    if (issues.isEmpty) {
      return _AnalysisResult(
        report: '✅ $langName: Không phát hiện lỗi theo các rule hiện tại.',
        fixedCode: '',
      );
    }

    final buf = StringBuffer();
    buf.writeln('🔎 $langName: Phát hiện ${issues.length} lỗi:');
    for (final it in issues) {
      buf.writeln('- Dòng ${it.line}: ${it.message}');
      buf.writeln('  Gợi ý: ${it.suggestion}');
    }

    return _AnalysisResult(report: buf.toString().trim(), fixedCode: '');
  }

  int? _findLineNumber(List<String> lines, bool Function(String line) predicate) {
    for (int i = 0; i < lines.length; i++) {
      if (predicate(lines[i])) return i + 1;
    }
    return null;
  }
}

class _Issue {
  final int line;
  final String message;
  final String suggestion;

  _Issue({required this.line, required this.message, required this.suggestion});
}

class _AnalysisResult {
  final String report;
  final String fixedCode;

  _AnalysisResult({required this.report, required this.fixedCode});
}