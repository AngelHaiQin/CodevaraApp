import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NhomScreen extends StatefulWidget {
  const NhomScreen({super.key});

  @override
  State<NhomScreen> createState() => _NhomScreenState();
}

class _NhomScreenState extends State<NhomScreen> {
  static const String _groupsApiUrl = 'https://codevara-api.com/groups';

  final ScrollController _groupScrollCtrl = ScrollController();

  // Thêm submission để lưu bài đã nộp
  List<Map<String, dynamic>> classes = [
    {
      'name': 'Lớp CNTT1 - Thầy Nam',
      'assignment': 'Viết hàm tính Fibonacci(n)',
      'deadline': '23/04/2026',
      'submitted': false,
      'score': null,
      'submission': null,
      'submissionFileName': null,
    },
    {
      'name': 'Lớp CNTT2 - Cô Lan',
      'assignment': 'Tạo API RESTful với Node.js',
      'deadline': '25/04/2026',
      'submitted': true,
      'score': 8.5,
      'submission': 'Đây là bài nộp của sinh viên...',
      'submissionFileName': null,
    },
    {
      'name': 'Lớp Web21 - Thầy Hùng',
      'assignment': 'HTML/CSS Landing Page',
      'deadline': '20/04/2026',
      'submitted': false,
      'score': null,
      'submission': null,
      'submissionFileName': null,
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

  @override
  void dispose() {
    _groupScrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToNewestGroup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_groupScrollCtrl.hasClients) return;
      _groupScrollCtrl.animateTo(
        _groupScrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ====== NEW: pick file submission (read bytes -> text) ======
  Future<void> _submitAssignmentByFile(int index) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        // bạn có thể thêm/bớt extension tuỳ app
        allowedExtensions: const [
          'txt',
          'js',
          'ts',
          'py',
          'dart',
          'java',
          'c',
          'cpp',
          'cs',
          'html',
          'css',
          'json',
          'md',
          'sql',
        ],
        withData: true, // quan trọng để web có bytes
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        _snack('Không đọc được file (bytes null).', Colors.red);
        return;
      }

      final content = utf8.decode(bytes, allowMalformed: true).trim();
      if (content.isEmpty) {
        _snack('File rỗng, không thể nộp.', Colors.red);
        return;
      }

      final assignment = classes[index]['assignment'];

      setState(() {
        classes[index]['submitted'] = true;
        classes[index]['score'] = null; // chưa chấm
        classes[index]['submission'] = content;
        classes[index]['submissionFileName'] = file.name;
      });

      _snack('✅ Đã nộp file "${file.name}" cho bài: $assignment', Colors.green);
    } catch (e) {
      _snack('Lỗi chọn file: $e', Colors.red);
    }
  }

  // ====== Submit by text (existing) ======
  void submitAssignment(int index) {
    final assignment = classes[index]['assignment'];
    final controller = TextEditingController(
      text: classes[index]['submission'] ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Nộp bài: $assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Nội dung bài',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await _submitAssignmentByFile(index);
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Nộp bằng file'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                _snack('Bài không được để trống!', Colors.red);
                return;
              }

              setState(() {
                classes[index]['submitted'] = true;
                classes[index]['score'] = null; // chưa chấm
                classes[index]['submission'] = text;
                classes[index]['submissionFileName'] = null; // nộp dạng text
              });

              Navigator.pop(dialogCtx);
              _snack('✅ Đã nộp bài: $assignment', Colors.green);
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }

  void _viewSubmission(int index) {
    final lop = classes[index];
    final text = lop['submission'] ?? '(Chưa có bài nộp)';
    final fileName = lop['submissionFileName'];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Bài đã nộp - ${lop['assignment']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (fileName != null) ...[
                Text(
                  'File: $fileName',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
              SelectableText(text),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _deleteSubmission(int index) {
    final name = classes[index]['name'];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận xóa bài'),
        content: Text('Bạn có chắc muốn xóa bài đã nộp của lớp: $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                classes[index]['submitted'] = false;
                classes[index]['score'] = null;
                classes[index]['submission'] = null;
                classes[index]['submissionFileName'] = null;
              });
              Navigator.pop(dialogCtx);
              _snack('Đã xóa bài nộp', Colors.orange);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void createNewClass() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Tạo lớp mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Tên lớp'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameCtrl.dispose();
              Navigator.pop(dialogCtx);
            },
            child: const Text('Hủy'),
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
                  'submission': null,
                  'submissionFileName': null,
                });
              });

              nameCtrl.dispose();
              Navigator.pop(dialogCtx);
              _snack('Đã tạo lớp: $name', Colors.green);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void createNewGroup() {
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Tạo nhóm mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
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
              Navigator.pop(dialogCtx);
            },
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();

              if (name.isEmpty) {
                _snack('Tên nhóm không được để trống!', Colors.red);
                return;
              }

              nameCtrl.dispose();
              Navigator.pop(dialogCtx);

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AlertDialog(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Text('Đang tạo nhóm...')),
                    ],
                  ),
                ),
              );

              // Try API (im lặng lỗi)
              try {
                final response = await http
                    .post(
                      Uri.parse(_groupsApiUrl),
                      headers: const {'Content-Type': 'application/json'},
                      body: jsonEncode({'name': name}),
                    )
                    .timeout(const Duration(seconds: 8));
                debugPrint('create group status=${response.statusCode} body=${response.body}');
              } on TimeoutException catch (e) {
                debugPrint('create group timeout: $e');
              } catch (e) {
                debugPrint('create group API failed: $e');
              }

              if (!mounted) return;
              Navigator.pop(context); // close loading

              setState(() {
                groups.add({
                  'name': name,
                  'memberCount': 1,
                  'description': 'Nhóm mới',
                });
              });
              _scrollToNewestGroup();

              _snack('✅ Đã tạo nhóm: $name', Colors.green);
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhóm Lớp Codevara'),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: createNewClass,
            icon: const Icon(Icons.class_),
            tooltip: 'Tạo lớp',
          ),
          IconButton(
            onPressed: createNewGroup,
            icon: const Icon(Icons.group),
            tooltip: 'Tạo nhóm',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final lop = classes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                (lop['name'] as String).isNotEmpty ? (lop['name'] as String)[0] : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lop['name'],
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(width: 4, color: Colors.orange[400]!),
                            ),
                          ),
                          child: Text(
                            'Bài tập: ${lop['assignment']}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (lop['submitted'])
                              Text(
                                lop['score'] != null ? 'Đã nộp - ${lop['score']} điểm' : 'Đã nộp - Chưa chấm',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else
                              Text(
                                'Chưa nộp',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (lop['submitted'])
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _viewSubmission(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[800],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Xem lại'),
                                  ),
                                  const SizedBox(width: 4),
                                  ElevatedButton(
                                    onPressed: () => _deleteSubmission(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[700],
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Xóa'),
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => submitAssignment(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Nộp bài'),
                                  ),
                                  const SizedBox(width: 6),
                                  OutlinedButton(
                                    onPressed: () => _submitAssignmentByFile(index),
                                    child: const Text('Nộp file'),
                                  ),
                                ],
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Các nhóm của bạn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.builder(
              controller: _groupScrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return Card(
                  margin: const EdgeInsets.only(right: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 160),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group['name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text('${group['memberCount']} thành viên'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}