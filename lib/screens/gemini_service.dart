import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyBSvNzF-CXIB7cyHibQY4Eka-_FqI-kbBI';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// Gửi prompt tới Gemini và lấy response *text thuần*.
  static Future<String> askAI(
    String prompt, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
  }) async {
    final url = Uri.parse('$_baseUrl?key=$_apiKey');

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.7,
        "maxOutputTokens": 1024,
      }
    });

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          return _parseResponse(response.body);
        }

        if (response.statusCode == 429) {
          if (attempt < maxRetries) {
            await Future.delayed(retryDelay * attempt);
            continue;
          }
          return 'Gemini API đang bị giới hạn (429 Too Many Requests). Thử lại sau ít phút.';
        }

        if (response.statusCode == 400 || response.statusCode == 403) {
          return 'API key không hợp lệ hoặc hết quyền. Chi tiết: ${response.body}';
        }

        return 'Lỗi API (${response.statusCode}): ${response.body}';
      } catch (e) {
        if (attempt == maxRetries) {
          return 'Không kết nối được Gemini API: $e';
        }
        await Future.delayed(retryDelay);
      }
    }

    return 'Không thể kết nối Gemini sau $maxRetries lần thử.';
  }


  /// Parse response API Gemini, trả về text duy nhất.
  static String _parseResponse(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        final promptFeedback = data['promptFeedback'];
        if (promptFeedback != null) {
          final blockReason = promptFeedback['blockReason'];
          if (blockReason != null) {
            return 'Nội dung bị chặn bởi safety filter: $blockReason';
          }
        }
        return 'AI không trả về dữ liệu.';
      }
      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return 'Không có nội dung phản hồi.';
      }
      return parts[0]['text']?.toString().trim() ?? 'Không có text.';
    } catch (e) {
      return 'Lỗi parse response: $e';
    }
  }
}