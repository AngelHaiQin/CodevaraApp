import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NhomScreen extends StatefulWidget {
  @override
  _NhomScreenState createState() => _NhomScreenState();
}

class _NhomScreenState extends State<NhomScreen> {
  List<Map<String, dynamic>> classes = [
    {
      'name': 'Lớp CNTT1 - Thầy Nam',
      'assignment': 'Viết hàm tính Fibonacci(n)',
      'deadline': '23/04/2026',
      'submitted': false,
      'score': null,
    },
    {
      'name': 'Lớp CNTT2 - Cô Lan',
      'assignment': 'Tạo API RESTful với Node.js',
      'deadline': '25/04/2026',
      'submitted': true,
      'score': 8.5,
    },
    {
      'name': 'Lớp Web21 - Thầy Hùng',
      'assignment': 'HTML/CSS Landing Page',
      'deadline': '20/04/2026',
      'submitted': false,
      'score': null,
    },
  ];

  List<Map<String, dynamic>> groups = [
    {
      'name': 'Nhóm lập trình CNTT',
      'memberCount': 5,
      'description': 'Nhóm làm đồ án cuối kỳ',
    },
    {
      'name': 'Nhóm web frontend',
      'memberCount': 3,
      'description': 'Nhóm làm trang landing page',
    },
  ];

  void submitAssignment(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bạn vừa nộp: ${classes[index]["assignment"]}'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      classes[index]['submitted'] = true;
      classes[index]['score'] = 8.5;
    });
  }

  void createNewClass() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tạo lớp mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: 'Tên lớp'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameCtrl.dispose();
              Navigator.pop(context);
            },
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              setState(() {
                classes.add({
                  'name': name,
                  'assignment': 'Bài tập mới',
                  'deadline': 'Chưa đặt',
                  'submitted': false,
                  'score': null,
                });
              });

              nameCtrl.dispose();
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã tạo lớp: $name'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void createNewGroup() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tạo nhóm mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Tên nhóm',
                hintText: 'Ví dụ: Nhóm CNTT Đà Lạt',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameCtrl.dispose();
              Navigator.pop(context);
            },
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              
              // ✅ BƯỚC 1: Validate input
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tên nhóm không được để trống!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // ✅ BƯỚC 2: Đóng dialog TRƯỚC
              nameCtrl.dispose();
              Navigator.pop(context);

              // ✅ BƯỚC 3: Hiện SnackBar loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đang tạo nhóm "$name"...'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 5),
                ),
              );

              // ✅ BƯỚC 4: Gọi API
              try {
                final response = await http.post(
                  Uri.parse('https://codevara-api.com/groups'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'name': name}),
                );

                // ✅ BƯỚC 5: Sau API response -> setState()
                if (response.statusCode == 201 || response.statusCode == 200) {
                  setState(() {
                    groups.add({
                      'name': name,
                      'memberCount': 1,
                      'description': 'Nhóm mới',
                    });
                  });

                  // ✅ BƯỚC 6: Hiện SnackBar success
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Đã tạo nhóm: $name'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Tạo nhóm thất bại (${response.statusCode})'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Lỗi kết nối: $e'),
                    backgroundColor: Colors.red,
                  ),
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
        title: Text('Nhóm Lớp Codevara'),
        backgroundColor: Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: createNewClass,
            icon: Icon(Icons.class_),
            tooltip: 'Tạo lớp',
          ),
          IconButton(
            onPressed: createNewGroup,
            icon: Icon(Icons.group),
            tooltip: 'Tạo nhóm',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                var lop = classes[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                lop['name'][0],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lop['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Hạn: ${lop['deadline']}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                width: 4,
                                color: Colors.orange[400]!,
                              ),
                            ),
                          ),
                          child: Text(
                            'Bài tập: ${lop['assignment']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (lop['submitted'])
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green[700],
                                      size: 20,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      lop['score'] != null
                                          ? 'Đã nộp - ${lop['score']} điểm'
                                          : 'Đã nộp',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      color: Colors.red[700],
                                      size: 20,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Chưa nộp',
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: () => submitAssignment(index),
                              icon: Icon(Icons.code),
                              label: Text(lop['submitted'] ? 'Xem lại' : 'Nộp bài'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              'Các nhóm của bạn',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                var group = groups[index];
                return Card(
                  margin: EdgeInsets.only(right: 8),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${group['memberCount']} thành viên'),
                      ],
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
}