import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int score = 0;
  int qIndex = 0;
  bool answered = false;

  final List<Map> questions = [
    {
      'q': 'console.log("Hi") output gì?',
      'a': ['"Hi"', '"Hi\\n"', 'undefined', 'Error'],
      'correct': 0,
    },
    {
      'q': 'function sum(a,b){return a+b} sum(2,3)?',
      'a': ['5', '23', 'NaN', 'function'],
      'correct': 0,
    },
    {
      'q': 'for(let i=0;i<3;i++) log(i) → ?',
      'a': ['0 1 2', '1 2 3', '0 1', 'Error'],
      'correct': 0,
    },
  ];

  void selectAnswer(int index) {
    setState(() {
      answered = true;
      if (index == questions[qIndex]['correct']) score++;
    });
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        qIndex = (qIndex + 1) % questions.length;
        answered = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Codevara Quiz'),
        backgroundColor: Color(0xFF1E3A8A),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              questions[qIndex]['q'],
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ...List.generate(4, (i) => Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ElevatedButton(
                onPressed: answered ? null : () => selectAnswer(i),
                style: ElevatedButton.styleFrom(
                  backgroundColor: answered
                    ? i == questions[qIndex]['correct'] 
                      ? Colors.green 
                      : Colors.red[300]
                    : Colors.orange,
                  padding: EdgeInsets.all(16),
                ),
                child: Text(
                  String.fromCharCode(65 + i) + '. ${questions[qIndex]['a'][i]}',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )),
            Spacer(),
            Text('Điểm: $score/3', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}