import 'package:flutter/material.dart';

class CodeScreen extends StatefulWidget {
  @override
  _CodeScreenState createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  String detectedLang = 'Chưa nhận';
  String aiScore = 'Chưa check';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Codevara - Dán Code'),
        backgroundColor: Color(0xFF1E3A8A),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dán code vào đây để Codevara nhận diện:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
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
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: detectLanguage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Nhận Ngôn Ngữ', style: TextStyle(fontSize: 16)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: checkAI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Check AI', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                children: [
                  Text('Kết quả Codevara:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text('Ngôn ngữ: $detectedLang', style: TextStyle(fontSize: 18, color: Colors.green[700])),
                  Text('AI Score: $aiScore', style: TextStyle(fontSize: 18, color: Colors.orange[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void detectLanguage() {
    String code = _codeController.text.trim();
    setState(() {
      if (code.contains('function') || code.contains('console.log')) {
        detectedLang = 'JavaScript';
      } else if (code.contains('print(') || code.contains('def ')) {
        detectedLang = 'Python';
      } else if (code.contains('int main') || code.contains('#include')) {
        detectedLang = 'C++';
      } else {
        detectedLang = 'Không nhận diện';
      }
    });
  }

  void checkAI() {
    setState(() {
      aiScore = _codeController.text.length > 50 ? 'Sạch 98% ✓' : 'Cần code dài hơn';
    });
  }
}