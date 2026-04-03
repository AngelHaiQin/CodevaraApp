import 'package:flutter/material.dart';
// ❌ XÓA dòng này đi
// import '../code_screen.dart';

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

  void submitAssignment(int index) {
    // ✅ Thay thế: hiển thị thông báo thay vì navigate
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bạn vừa nộp: ${classes[index]["assignment"]}'),
        backgroundColor: Colors.green,
      ),
    );
    
    setState(() {
      classes[index]['submitted'] = true;
      classes[index]['score'] = 8.5; // Điểm mặc định
    });
  }

  void createNewClass() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tạo lớp mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Tên lớp'),
              onSubmitted: (value) {
                setState(() {
                  classes.add({
                    'name': value,
                    'assignment': 'Bài tập mới',
                    'deadline': 'Chưa đặt',
                    'submitted': false,
                    'score': null,
                  });
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
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
      ),
      body: ListView.builder(
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
                  // Tên lớp + Thầy cô
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(lop['name'][0], style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lop['name'],
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text('Hạn: ${lop['deadline']}', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  
                  // Bài tập
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Trạng thái nộp bài
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
                              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                              SizedBox(width: 4),
                              Text(
                                lop['score'] != null 
                                  ? 'Đã nộp - ${lop['score']} điểm' 
                                  : 'Đã nộp',
                                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
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
                              Icon(Icons.schedule, color: Colors.red[700], size: 20),
                              SizedBox(width: 4),
                              Text(
                                'Chưa nộp',
                                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createNewClass,
        icon: Icon(Icons.group_add),
        label: Text('Tạo lớp'),
        backgroundColor: Colors.green,
      ),
    );
  }
}