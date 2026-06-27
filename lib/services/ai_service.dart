import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _backendUrl = 'https://mahmadmurodov-telegram-bot.hf.space';

  static Future<String> chat(
    String userMessage, {
    String systemPrompt = 'You are Superior AI. Be helpful.',
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/v1/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': userMessage}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['result'] ?? 'Ҷавоб холӣ аст';
        }
        return '❌ ${data['error'] ?? 'Хато'}';
      }
      if (response.statusCode == 503) {
        return '⏳ Модел бор мешавад. 30 сония интизор шав.';
      }
      return '❌ Хато ${response.statusCode}';
    } catch (e) {
      return '❌ Шабака: $e';
    }
  }

  static Future<String> translate(String text, String targetLang) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/v1/ai/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'target': targetLang}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? '';
      }
      return '❌ Тарҷума нашуд';
    } catch (e) {
      return '❌ $e';
    }
  }

  static Future<String> summarize(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/v1/ai/summarize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? '';
      }
      return '❌ Хулоса нашуд';
    } catch (e) {
      return '❌ $e';
    }
  }

  static Future<String> fixCode(String code) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/v1/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': 'Fix bugs in this code and explain what was fixed:\n\n$code',
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? '';
      }
      return '❌ Хато';
    } catch (e) {
      return '❌ $e';
    }
  }

  static Future<String> improveText(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/v1/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': 'Improve the grammar and style of this text:\n\n$text',
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? '';
      }
      return '❌ Хато';
    } catch (e) {
      return '❌ $e';
    }
  }
}
