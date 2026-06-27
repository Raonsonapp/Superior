import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl = 'https://YOUR_HF_SPACE.hf.space/api/v1/ai';

  static Future<String> chat(String message, {String? system}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        if (system != null) 'system': system,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] ?? 'Ҷавоб дода нашуд';
    }
    throw Exception('AI хатогӣ: ${response.statusCode}');
  }

  static Future<String> translate(String text, String target) async {
    final response = await http.post(
      Uri.parse('$baseUrl/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text, 'target': target}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] ?? '';
    }
    throw Exception('Тарҷума нашуд');
  }

  static Future<String> summarize(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/summarize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['result'] ?? '';
    }
    throw Exception('Хулоса нашуд');
  }
}
