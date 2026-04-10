import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef QuizCompleteCallback = void Function(String topic, int score, int total);

class QuizScreen extends StatefulWidget {
  QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

/// ✅ Đây là màn MENU (2 mục: chọn ngôn ngữ + gần đây)
class _QuizScreenState extends State<QuizScreen> {
  static const _bg = Color(0xFF0F0F23);
  static const _card = Color(0xFF1E1E2E);
  static const _primary = Color(0xFF6366F1);

  final List<String> _topics = const ['JavaScript', 'Python', 'SQL'];

  List<QuizHistoryItem> _recent = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('quiz_recent') ?? <String>[];
    final items = raw
        .map((e) => QuizHistoryItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();

    if (!mounted) return;
    setState(() {
      _recent = items;
      _loading = false;
    });
  }

  Future<void> _saveToRecent(String topic, int score, int total) async {
    final prefs = await SharedPreferences.getInstance();
    final item = QuizHistoryItem(
      topic: topic,
      score: score,
      total: total,
      completedAt: DateTime.now(),
    );

    // đưa mới nhất lên đầu, bỏ trùng topic, giới hạn 10
    final updated = <QuizHistoryItem>[
      item,
      ..._recent.where((x) => x.topic != topic),
    ].take(10).toList();

    await prefs.setStringList(
      'quiz_recent',
      updated.map((x) => jsonEncode(x.toJson())).toList(),
    );

    if (!mounted) return;
    setState(() => _recent = updated);
  }

  Future<void> _openQuiz(String topic) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPlayScreen(
          topic: topic,
          onQuizComplete: (t, s, total) => _saveToRecent(t, s, total),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Quiz Game', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Quiz theo ngôn ngữ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 12),
                ..._topics.map((topic) => _TopicTile(
                      title: topic,
                      onTap: () => _openQuiz(topic),
                    )),
                const SizedBox(height: 24),
                const Text(
                  'Đã làm gần đây',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 12),
                if (_recent.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Text(
                      'Chưa có bài nào. Chọn 1 ngôn ngữ để bắt đầu.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  ..._recent.map((item) {
                    final percent = (item.score / item.total * 100).round();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: _primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.topic,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.score}/${item.total} • $percent% • ${_formatTime(item.completedAt)}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openQuiz(item.topic),
                            child: const Text('Làm lại', style: TextStyle(color: _primary)),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
    );
  }

  static String _formatTime(DateTime dt) {
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _TopicTile extends StatelessWidget {
  static const _card = Color(0xFF1E1E2E);
  static const _primary = Color(0xFF6366F1);

  final String title;
  final VoidCallback onTap;

  const _TopicTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.code, color: _primary),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        subtitle: const Text('Nhấn để bắt đầu', style: TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      ),
    );
  }
}

/// ✅ Màn làm bài + kết quả
class QuizPlayScreen extends StatefulWidget {
  final String topic;
  final QuizCompleteCallback? onQuizComplete;

  const QuizPlayScreen({
    super.key,
    required this.topic,
    this.onQuizComplete,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen>
    with SingleTickerProviderStateMixin {
  static const _bg = Color(0xFF0F0F23);
  static const _card = Color(0xFF1E1E2E);
  static const _primary = Color(0xFF6366F1);

  static const _optionStart = Color(0xFF1F2937);
  static const _optionEnd = Color(0xFF111827);
  static const _correctStart = Color(0xFF10B981);
  static const _correctEnd = Color(0xFF059669);

  int currentQuestion = 0;
  int score = 0;
  bool showResult = false;
  bool quizCompleted = false;

  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;

  late final List<QuizQuestion> questions;

  @override
  void initState() {
    super.initState();
    questions = _getQuestionsForTopic(widget.topic);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<QuizQuestion> _getQuestionsForTopic(String topic) {
    switch (topic) {
      case 'JavaScript':
        return const [
          QuizQuestion(
            question: "Hàm Fibonacci đệ quy sai ở đâu?",
            code:
                "function fibonacci(n) {\n  if (n <= 1) return n;\n  return fibonacci(n-1) + fibonacci(n-2);\n}",
            options: ["Không có lỗi", "Thiếu base case n=0", "Không xử lý số âm", "Không tối ưu"],
            correct: 0,
          ),
          QuizQuestion(
            question: "HTML onclick này gọi hàm nào?",
            code: "<button onclick=\"checkAI()\">Check AI</button>",
            options: ["checkAi()", "checkAI()", "CheckAI()", "check_ai()"],
            correct: 1,
          ),
        ];

      case 'Python':
        return const [
          QuizQuestion(
            question: "List comprehension này tạo gì?",
            code: "[x**2 for x in range(5) if x % 2 == 0]",
            options: ["[0,1,2,3,4]", "[0,4,16]", "[0,2,4]", "[1,3]"],
            correct: 1,
          ),
          QuizQuestion(
            question: "Dict này có key 'age' không?",
            code: "person = {'name': 'John'}",
            options: ["Có", "Không", "Lỗi syntax", "None"],
            correct: 1,
          ),
        ];

      case 'SQL':
        return const [
          QuizQuestion(
            question: "SQL JOIN này trả về gì?",
            code: "SELECT users.name, orders.total\nFROM users\nJOIN orders ON users.id = orders.user_id",
            options: ["Tất cả user có order", "Tất cả user", "Tất cả order", "User không có order"],
            correct: 0,
          ),
          QuizQuestion(
            question: "GROUP BY này làm gì?",
            code: "SELECT department, COUNT(*) FROM employees GROUP BY department",
            options: ["Đếm nhân viên theo phòng ban", "Sắp xếp theo phòng ban", "Lọc phòng ban", "Xóa trùng lặp"],
            correct: 0,
          ),
        ];

      default:
        return const [
          QuizQuestion(
            question: "Câu hỏi mẫu",
            code: "print('Hello')",
            options: ["A", "B", "C", "D"],
            correct: 0,
          ),
        ];
    }
  }

  void selectAnswer(int index) {
    if (showResult || quizCompleted) return;

    setState(() => showResult = true);

    if (index == questions[currentQuestion].correct) {
      score++;
      _animationController
        ..reset()
        ..forward();
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        if (currentQuestion < questions.length - 1) {
          currentQuestion++;
          showResult = false;
        } else {
          quizCompleted = true;
          widget.onQuizComplete?.call(widget.topic, score, questions.length);
        }
      });
    });
  }

  void restartQuiz() {
    setState(() {
      currentQuestion = 0;
      score = 0;
      showResult = false;
      quizCompleted = false;
    });

    _animationController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (currentQuestion + 1) / questions.length;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: quizCompleted ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Code Quiz',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(widget.topic, style: const TextStyle(fontSize: 16, color: Colors.white70)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.quiz, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text('${currentQuestion + 1}/${questions.length}', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(_primary),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: quizCompleted
                  ? _buildResultScreen()
                  : AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(scale: _scaleAnimation.value, child: child);
                      },
                      child: _buildQuestionContent(questions[currentQuestion]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent(QuizQuestion question) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: SelectableText(
              question.code,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 15, color: Color(0xFFE4E4E7), height: 1.5),
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: ListView.builder(
              itemCount: question.options.length,
              itemBuilder: (context, index) {
                final isCorrect = showResult && index == question.correct;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: showResult ? null : () => selectAnswer(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: showResult
                              ? (isCorrect ? const [_correctStart, _correctEnd] : const [_optionStart, _optionEnd])
                              : const [_optionStart, _optionEnd],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: showResult
                              ? (isCorrect ? Colors.green.withOpacity(0.5) : Colors.transparent)
                              : Colors.white.withOpacity(0.1),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                              child: showResult
                                  ? Icon(isCorrect ? Icons.check : Icons.close,
                                      color: isCorrect ? Colors.white : Colors.white60, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: showResult ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final total = questions.length;
    final percentage = (score / total * 100).round();
    final resultText = percentage >= 80
        ? 'Xuất sắc!'
        : percentage >= 60
            ? 'Tốt!'
            : percentage >= 40
                ? 'Cần cố gắng!'
                : 'Học lại nhé!';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 90, color: _primary),
          const SizedBox(height: 16),
          Text(resultText, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                _scoreRow('Ngôn ngữ', widget.topic),
                const Divider(color: Color(0x22FFFFFF)),
                _scoreRow('Điểm', '$score / $total'),
                const Divider(color: Color(0x22FFFFFF)),
                _scoreRow('Phần trăm', '$percentage%'),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Thoát', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: restartQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Thử lại', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(String left, String right) {
    return Row(
      children: [
        Expanded(child: Text(left, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        Text(right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}

class QuizQuestion {
  final String question;
  final String code;
  final List<String> options;
  final int correct;

  const QuizQuestion({
    required this.question,
    required this.code,
    required this.options,
    required this.correct,
  });
}

class QuizHistoryItem {
  final String topic;
  final int score;
  final int total;
  final DateTime completedAt;

  QuizHistoryItem({
    required this.topic,
    required this.score,
    required this.total,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'score': score,
        'total': total,
        'completedAt': completedAt.toIso8601String(),
      };

  static QuizHistoryItem fromJson(Map<String, dynamic> json) {
    return QuizHistoryItem(
      topic: json['topic'] as String,
      score: json['score'] as int,
      total: json['total'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}