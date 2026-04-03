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
  String code = _codeController.text.trim().toLowerCase();
  
  if (code.isEmpty) {
    setState(() => detectedLang = 'Dán code trước nhé! 😊');
    return;
  }

  // 10 ngôn ngữ phổ biến + emoji
  if (code.contains('function') || code.contains('console.log') || code.contains('document.')) {
    detectedLang = 'JavaScript 🟡';
  } else if (code.contains('print(') || code.contains('def ') || code.contains('import ')) {
    detectedLang = 'Python 🐍';
  } else if (code.contains('int main') || code.contains('#include')) {
    detectedLang = 'C/C++ ⚙️';
  } else if (code.contains('public class') || code.contains('system.out')) {
    detectedLang = 'Java ☕';
  } else if (code.contains('<html') || code.contains('<!doctype')) {
    detectedLang = 'HTML/CSS 🌐';
  } else if (code.contains('select') && code.contains('from')) {
    detectedLang = 'SQL 🗄️';
  } else if (code.contains('let ') || code.contains('const ')) {
    detectedLang = 'TypeScript 🔵';
  } else if (code.contains('fn main') || code.contains('rust')) {
    detectedLang = 'Rust 🦀';
  } else {
    detectedLang = 'Code hay! 100+ ngôn ngữ khác 🤖';
  }
  
  setState(() {});
}

void checkAI() async {
  setState(() => aiScore = 'Codevara đang check... 🔍');
  
  // Delay 2 giây (như API thật)
  await Future.delayed(Duration(seconds: 2));
  
  String code = _codeController.text.trim();
  if (code.length < 30) {
    setState(() => aiScore = '⚠️ Code quá ngắn, cần >30 ký tự');
    return;
  }
  
  // Fake AI score thông minh
  int fakeScore = ((code.length * 0.8 + 15) % 85 + 15).toInt();
  
  setState(() {
    if (fakeScore > 75) {
      aiScore = '⚠️ AI detected ${fakeScore}% 🤖';
    } else if (fakeScore > 40) {
      aiScore = '⚡ Có thể AI hỗ trợ ${fakeScore}%';
    } else {
      aiScore = '✅ Code tự viết ${100-fakeScore}% 🥇';
    }
  });
}
}