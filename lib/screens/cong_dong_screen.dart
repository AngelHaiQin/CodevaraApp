import 'package:flutter/material.dart';

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
      'comments': 5,
      'time': '2h',
      'language': 'JavaScript 🟡'
    },
    {
      'user': 'LanSQL', 
      'avatar': 'L',
      'code': 'SELECT users.name, orders.total\nFROM users\nJOIN orders ON users.id = orders.user_id\nWHERE orders.date > "2026-01-01";',
      'likes': 15, 
      'comments': 3,
      'time': '5h',
      'language': 'SQL 🗄️'
    },
    {
      'user': 'HùngWeb', 
      'avatar': 'H',
      'code': '<div class="container">\n  <h1>Codevara</h1>\n  <button onclick="checkAI()">Check AI</button>\n</div>',
      'likes': 8, 
      'comments': 2,
      'time': '1 ngày',
      'language': 'HTML 🌐'
    }
  ];

  void toggleLike(int index) {
    setState(() {
      posts[index]['likes'] += posts[index]['likes'] > 0 ? -1 : 1;
    });
  }

  void postNewCode() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Đăng code mới'),
        content: TextField(
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Code của bạn',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (code) {
            setState(() {
              posts.insert(0, {
                'user': 'Bạn',
                'avatar': 'B',
                'code': code,
                'likes': 0,
                'comments': 0,
                'time': 'Vừa xong',
                'language': 'Auto detect 🤖'
              });
            });
            Navigator.pop(context);
          },
        ),
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
                // Header
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple[100],
                    child: Text(post['avatar']),
                  ),
                  title: Text(post['user'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('• ${post['time']}'),
                  trailing: Text(post['language'], style: TextStyle(color: Colors.green)),
                ),
                // Code block
                Container(
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: SelectableText(
                    post['code'],
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
                // Actions
                Row(
                  children: [
                    IconButton(
                      onPressed: () => toggleLike(index),
                      icon: Icon(post['likes'] > 0 ? Icons.thumb_up : Icons.thumb_up_outlined),
                    ),
                    Text('${post['likes']}'),
                    SizedBox(width: 20),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.comment),
                    ),
                    Text('${post['comments']}'),
                  ],
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