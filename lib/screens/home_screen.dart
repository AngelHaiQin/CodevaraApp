import 'package:flutter/material.dart';
import 'code_screen.dart';
import 'quiz_screen.dart';
import 'nhom_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color bg1 = Color(0xFF6366F1);
  static const Color bg2 = Color(0xFFA78BFA);
  static const Color bg3 = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bg1, bg2, bg3],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ===== HEADER =====
              Padding(
                padding: const EdgeInsets.only(
                  top: 40,
                  bottom: 30,
                ),
                child: Column(
                  children: const [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 70,
                    ),

                    SizedBox(height: 16),

                    Text(
                      'CODEVARA',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      'Học Code Không Cần AI',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ===== MENU DỌC =====
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildMenuCard(
                        icon: Icons.code,
                        title: 'Dán Code',
                        subtitle: 'Fix lỗi • Compile • AI Chat',
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CodevaraScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildMenuCard(
                        icon: Icons.quiz,
                        title: 'Quiz Game',
                        subtitle: 'Luyện tập code bằng quiz',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QuizScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildMenuCard(
                        icon: Icons.group,
                        title: 'Nhóm Lớp',
                        subtitle: 'Học và chia sẻ cùng bạn bè',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NhomScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ===== FOOTER =====
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 20,
                ),
                child: Text(
                  'Codevara AI © 2026',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(28),

          border: Border.all(
            color: Colors.white.withOpacity(0.22),
            width: 1.5,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 38,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}