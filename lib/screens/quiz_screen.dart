import 'package:flutter/material.dart';
import 'dart:math';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int currentQuestion = 0;
  int score = 0;
  bool showResult = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  List<QuizQuestion> questions = [
    QuizQuestion(
      question: "Hàm Fibonacci đệ quy sai ở đâu?",
      code: "function fibonacci(n) {\n  if (n <= 1) return n;\n  return fibonacci(n-1) + fibonacci(n-2);\n}",
      options: [
        "Không có lỗi",
        "Thiếu base case n=0",
        "Không xử lý số âm",
        "Không tối ưu"
      ],
      correct: 0,
    ),
    QuizQuestion(
      question: "SQL JOIN này trả về gì?",
      code: "SELECT users.name, orders.total\nFROM users\nJOIN orders ON users.id = orders.user_id",
      options: [
        "Tất cả user có order",
        "Tất cả user",
        "Tất cả order",
        "User không có order"
      ],
      correct: 0,
    ),
    QuizQuestion(
      question: "HTML onclick này gọi hàm nào?",
      code: "<button onclick=\"checkAI()\">Check AI</button>",
      options: [
        "checkAi()",
        "checkAI()",
        "CheckAI()",
        "check_ai()"
      ],
      correct: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
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

  void selectAnswer(int index) {
    setState(() {
      showResult = true;
    });

    if (index == questions[currentQuestion].correct) {
      score++;
      _animationController.forward(from: 0.0);
    }

    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        if (currentQuestion < questions.length - 1) {
          currentQuestion++;
          showResult = false;
        } else {
          Navigator.pop(context, score);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];
    final progress = (currentQuestion + 1) / questions.length;

    return Scaffold(
      backgroundColor: Color(0xFF0F0F23),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Code Quiz',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.quiz, color: Colors.white70, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '${currentQuestion + 1}/${questions.length}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF6366F1),
                ),
              ),
            ),

            SizedBox(height: 30),

            // Question Content
            Expanded(
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question
                          Text(
                            question.question,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 20),

                          // Code Block
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: SelectableText(
                              question.code,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                color: Color(0xFFE4E4E7),
                                height: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 30),

                          // Answer Buttons
                          Expanded(
                            child: ListView.builder(
                              itemCount: question.options.length,
                              itemBuilder: (context, index) {
                                final isCorrect = showResult &&
                                    index == question.correct;
                                final isSelected = showResult && index == question.correct;
                                
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: GestureDetector(
                                    onTap: showResult ? null : () => selectAnswer(index),
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      height: 70,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: showResult
                                              ? isCorrect
                                                  ? [Color(0xFF10B981), Color(0xFF059669)]
                                                  : [Color(0xFF1F2937), Color(0xFF111827)]
                                              : [Color(0xFF1F2937), Color(0xFF111827)],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: showResult
                                              ? isCorrect
                                                  ? Colors.green.withOpacity(0.5)
                                                  : Colors.transparent
                                              : Colors.white.withOpacity(0.1),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: showResult
                                                  ? Icon(
                                                      isCorrect
                                                          ? Icons.check
                                                          : Icons.close,
                                                      color: isCorrect
                                                          ? Colors.white
                                                          : Colors.white60,
                                                      size: 16,
                                                    )
                                                  : null,
                                            ),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                question.options[index],
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: showResult
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final String code;
  final List<String> options;
  final int correct;

  QuizQuestion({
    required this.question,
    required this.code,
    required this.options,
    required this.correct,
  });
}