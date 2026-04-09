import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CongDongScreen extends StatefulWidget {
  @override
  _CongDongScreenState createState() => _CongDongScreenState();
}

class _CongDongScreenState extends State<CongDongScreen> {
  List posts = [
    {
      'user': 'NamDev',
      'avatar': 'N',
      'code': 'function fibonacci(n) {\n  if (n <= 1) return n;\n  return fibonacci(n-1) + fibonacci(n-2);\n}',
      'likes': 23,
      'comments': [
        {'user': 'LanSQL', 'text': 'Good recursion!'}
      ],
      'time': '2h',
      'language': 'JavaScript 🟡',
      'liked': false,
    },
    {
      'user': 'LanSQL',
      'avatar': 'L',
      'code': 'SELECT users.name, orders.total\nFROM users\nJOIN orders ON users.id = orders.user_id\nWHERE orders.date > "2026-01-01";',
      'likes': 15,
      'comments': [
        {'user': 'NamDev', 'text': 'Clear query!'}
      ],
      'time': '5h',
      'language': 'SQL 🗄️',
      'liked': false,
    },
    {
      'user': 'HùngWeb',
      'avatar': 'H',
      'code': '<div class="container">\n  <h1>Codevara</h1>\n  <button onclick="checkAI()">Check AI</button>\n</div>',
      'likes': 8,
      'comments': [
        {'user': 'Bạn', 'text': 'Cute layout.'}
      ],
      'time': '1 ngày',
      'language': 'HTML 🌐',
      'liked': false,
    },
  ];

  void toggleLike(int index) {
    final post = posts[index];
    if (!post['liked']) {
      setState(() {
        post['liked'] = true;
        post['likes'] += 1;
      });
    }
  }

  void createNewComment(int index) {
    final textCtrl = TextEditingController();
    final user = ['NamDev', 'LanSQL', 'HùngWeb'].elementAt(index % 3);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm bình luận'),
        content: TextField(
          controller: textCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Bình luận của bạn',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              textCtrl.dispose();
              Navigator.pop(context);
            },
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = textCtrl.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Bình luận không được để trống!'), backgroundColor: Colors.red),
                );
                return;
              }

              textCtrl.dispose();
              Navigator.pop(context);

              final comment = {'user': user, 'text': text};
              setState(() {
                posts[index]['comments'].add(comment);
              });

              try {
                final response = await http.post(
                  Uri.parse('https://codevara-api.com/posts/${index}/comments'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'user': user, 'text': text}),
                );

                if (response.statusCode == 201 || response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã bình luận!'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {}
            },
            child: Text('Bình luận'),
          ),
        ],
      ),
    );
  }

  void postNewCode() {
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đăng code mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Code của bạn',
                border: OutlineInputBorder(),
                hintText: 'Nhập code cần đăng...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              codeCtrl.dispose();
              Navigator.pop(context);
            },
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Code không được để trống!'), backgroundColor: Colors.red),
                );
                return;
              }

              codeCtrl.dispose();
              Navigator.pop(context);

              // ✅ THÊM BÀI NGAY LẬP TỨC (trước khi gọi API)
              setState(() {
                posts.insert(0, {
                  'user': 'Bạn',
                  'avatar': 'B',
                  'code': code,
                  'likes': 0,
                  'comments': [],
                  'time': 'Vừa xong',
                  'language': 'Auto detect 🤖',
                  'liked': false,
                });
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang đăng code lên server...'), backgroundColor: Colors.blue),
              );

              // Gọi API ở background
              try {
                final response = await http.post(
                  Uri.parse('https://codevara-api.com/posts'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'code': code, 'user': 'Bạn'}),
                );

                if (response.statusCode != 201 && response.statusCode != 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lưu server thất bại (${response.statusCode})'), backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi server: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cộng Đồng Codevara'),
        backgroundColor: Color(0xFF1E3A8A),
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          var post = posts[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    child: Text(post['avatar']),
                  ),
                  title: Text(post['user'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('• ${post['time']}'),
                  trailing: Text(post['language'], style: TextStyle(color: Colors.green)),
                ),
                Container(
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: SelectableText(
                    post['code'],
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => toggleLike(index),
                        icon: Icon(
                          post['liked'] ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: post['liked'] ? Colors.blue : null,
                        ),
                      ),
                      Text('${post['likes']}'),
                      SizedBox(width: 20),
                      IconButton(
                        onPressed: () => createNewComment(index),
                        icon: Icon(Icons.comment),
                      ),
                      Text('${post['comments'].length}'),
                    ],
                  ),
                ),
                if (post['comments'].isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: post['comments']
                          .map<Widget>((comment) => Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${comment['user']}: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: comment['text']),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: postNewCode,
        icon: Icon(Icons.add),
        label: Text('Đăng code'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}