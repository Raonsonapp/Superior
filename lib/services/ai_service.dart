import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // HuggingFace Inference API — Qwen3-8B (ройгон)
  static const String _baseUrl =
      'https://api-inference.huggingface.co/models/Qwen/Qwen3-8B';

  // Агар HF_TOKEN дошта бошӣ — ин ҷо гузор, вагарна холӣ монда мешавад
  static const String _hfToken = '';

  static Future<String> chat(
    String userMessage, {
    String systemPrompt = 'You are a helpful AI assistant. Answer clearly and concisely.',
    List<Map<String, String>> history = const [],
  }) async {
    // Qwen3 ChatML format
    final StringBuffer prompt = StringBuffer();

    prompt.write('<|im_start|>system\n$systemPrompt<|im_end|>\n');

    for (final msg in history) {
      final role = msg['role'] ?? 'user';
      final content = msg['content'] ?? '';
      prompt.write('<|im_start|>$role\n$content<|im_end|>\n');
    }

    prompt.write('<|im_start|>user\n$userMessage<|im_end|>\n');
    prompt.write('<|im_start|>assistant\n');

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_hfToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_hfToken';
    }

    final body = jsonEncode({
      'inputs': prompt.toString(),
      'parameters': {
        'max_new_tokens': 512,
        'temperature': 0.7,
        'top_p': 0.9,
        'do_sample': true,
        'return_full_text': false,
        'stop': ['<|im_end|>'],
      },
    });

    try {
      final response = await http
          .post(Uri.parse(_baseUrl), headers: headers, body: body)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 503) {
        return '⏳ Модел дар ҳоли бор шудан аст (~20 сония). Дубора кӯшиш кунед.';
      }

      if (response.statusCode != 200) {
        return '❌ Хато ${response.statusCode}: ${response.body}';
      }

      final data = jsonDecode(response.body);
      String result = '';

      if (data is List && data.isNotEmpty) {
        result = data[0]['generated_text'] ?? '';
      } else if (data is Map) {
        result = data['generated_text'] ?? '';
      }

      // Тозакунии натиҷа аз stop tokens
      result = result.replaceAll('<|im_end|>', '').trim();
      result = result.replaceAll('<|im_start|>', '').trim();

      return result.isEmpty ? 'Ҷавоб дода нашуд. Дубора кӯшиш кунед.' : result;
    } catch (e) {
      return '❌ Хатогии шабака: $e';
    }
  }

  static Future<String> translate(String text, String targetLang) {
    final prompts = {
      'ru': 'Переведи следующий текст на русский язык. Дай только перевод, без объяснений.',
      'en': 'Translate the following text to English. Give only the translation, no explanations.',
      'tg': 'Матни зеринро ба тоҷикӣ тарҷума кун. Фақат тарҷумаро бинавис, тавзеҳ лозим нест.',
    };
    return chat(text, systemPrompt: prompts[targetLang] ?? prompts['en']!);
  }

  static Future<String> summarize(String text) {
    return chat(
      text,
      systemPrompt:
          'Summarize the following text in 3-5 clear sentences. Be concise and informative.',
    );
  }

  static Future<String> fixCode(String code) {
    return chat(
      code,
      systemPrompt:
          'You are an expert programmer. Find and fix bugs in the code. Explain what was fixed.',
    );
  }

  static Future<String> improveText(String text) {
    return chat(
      text,
      systemPrompt:
          'Improve the writing style and grammar of the following text. Keep the meaning the same.',
    );
  }
}
