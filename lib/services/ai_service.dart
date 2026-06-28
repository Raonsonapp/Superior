import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _backendUrl =
      'https://mahmadmurodov-telegram-bot.hf.space';

  static Future<String> chat(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/v1/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? data['reply'] ?? 'Ҷавоб холӣ аст';
      }
      if (response.statusCode == 503) {
        return '⏳ Модел бор мешавад. 30 сония интизор шав.';
      }
      return '❌ Хато ${response.statusCode}: ${response.body}';
    } catch (e) {
      return '❌ Шабака: $e';
    }
  }

  static Future<String> translate(String text, String target) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_backendUrl/api/v1/ai/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'target': target}),
          )
          .timeout(const Duration(seconds: 90));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'] ?? data['reply'] ?? '';
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
        return data['result'] ?? data['reply'] ?? '';
      }
      return '❌ Хулоса нашуд';
    } catch (e) {
      return '❌ $e';
    }
  }
}
