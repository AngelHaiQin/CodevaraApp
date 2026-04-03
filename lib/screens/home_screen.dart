import 'package:flutter/material.dart';
import 'code_screen.dart';
import 'quiz_screen.dart';
import 'nhom_screen.dart';
import 'cong_dong_screen.dart';  // ✅ Cộng Đồng

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFFA78BFA), Color(0xFF06B6D4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            // Logo (giữ nguyên)
            Padding(
              padding: EdgeInsets.only(top: 60, bottom: 80),
              child: Column(
                children: [
                  Text('CODEVARA', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4)),
                  SizedBox(height: 8),
                  Text('Học Code Không AI', style: TextStyle(fontSize: 20, color: Colors.white70)),
                ],
              ),
            ),
            
            // 4 Icon Figma
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Row 1
                    Row(children: [
                      Expanded(child: _buildIconButton(Icons.code, 'Dán Code', () => Navigator.push(context, MaterialPageRoute(builder: (_) => CodeScreen())), Colors.green)),
                      SizedBox(width: 20),
                      Expanded(child: _buildIconButton(Icons.quiz, 'Quiz Game', () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen())), Colors.orange)),
                    ]),
                    SizedBox(height: 30),
                    
                    // Row 2 ✅ NHÓM + CỘNG ĐỒNG
                    Row(children: [
                      Expanded(child: _buildIconButton(Icons.group, 'Nhóm Lớp', () => Navigator.push(context, MaterialPageRoute(builder: (_) => NhomScreen())), Colors.purple)),
                      SizedBox(width: 20),
                      Expanded(child: _buildIconButton(Icons.chat_bubble_outline, 'Cộng Đồng', () => Navigator.push(context, MaterialPageRoute(builder: (_) => CongDongScreen())), Colors.pink)),
                    ]),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // _buildIconButton() giữ nguyên code cũ
  Widget _buildIconButton(IconData icon, String label, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(color: color.withOpacity(0.3), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(label, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}