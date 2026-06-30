import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

/// Сервиси алоқа бо backend-и Superior AI.
/// Streaming (SSE), таърихи пурраи гуфтугӯ, тарҷума ва хулоса.
class AIService {
  static const String backendUrl =
      'https://mahmadmurodov-telegram-bot.hf.space';

  /// Чати стримӣ — ҷавобро ҳарф-ба-ҳарф ҳамчун Stream бармегардонад.
  /// [history] — ҳамаи паёмҳои гуфтугӯ (бе паёми streaming-и ҷорӣ).
  static Stream<String> chatStream(
    List<ChatMessage> history,
    String model,
  ) async* {
    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$backendUrl/api/v1/ai/chat/stream'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': model,
        'messages': history.map((m) => m.toApi()).toList(),
      });

      final response = await client.send(request).timeout(
            const Duration(seconds: 180),
          );

      if (response.statusCode != 200) {
        yield '❌ Хатои сервер (${response.statusCode})';
        return;
      }

      final lines = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lines) {
        if (!line.startsWith('data:')) continue;
        final payload = line.substring(5).trim();
        if (payload.isEmpty) continue;
        if (payload == '[DONE]') return;

        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          if (data['error'] != null) {
            yield '❌ ${data['error']}';
            return;
          }
          final content = data['content'];
          if (content is String && content.isNotEmpty) {
            yield content;
          }
        } catch (_) {
          // қисмҳои нодуруст рад мешаванд
        }
      }
    } catch (e) {
      yield '❌ Шабака: $e';
    } finally {
      client.close();
    }
  }

  /// Чати оддӣ (бе streaming) — ҳамчун fallback.
  static Future<String> chat(List<ChatMessage> history, String model) async {
    try {
      final response = await http
          .post(
            Uri.parse('$backendUrl/api/v1/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'messages': history.map((m) => m.toApi()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['result'] ?? data['reply'] ?? 'Ҷавоб холӣ аст';
      }
      return '❌ Хато ${response.statusCode}';
    } catch (e) {
      return '❌ Шабака: $e';
    }
  }

  static Future<String> translate(String text, String target) async {
    try {
      final response = await http
          .post(
            Uri.parse('$backendUrl/api/v1/ai/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'target': target}),
          )
          .timeout(const Duration(seconds: 90));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
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
            Uri.parse('$backendUrl/api/v1/ai/summarize'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 90));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['result'] ?? '';
      }
      return '❌ Хулоса нашуд';
    } catch (e) {
      return '❌ $e';
    }
  }
}
