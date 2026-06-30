import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';

/// Нигоҳдории маҳаллии гуфтугӯҳо ва танзимот (shared_preferences).
class StorageService {
  static const _convKey = 'superior_conversations_v2';
  static const _modelKey = 'superior_model';

  static Future<List<Conversation>> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_convKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final convs = list
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
      convs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return convs;
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveConversations(List<Conversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(conversations.map((c) => c.toJson()).toList());
    await prefs.setString(_convKey, raw);
  }

  static Future<String> loadModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelKey) ?? 'Qwen/Qwen3-8B';
  }

  static Future<void> saveModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
  }
}

/// Моделҳои дастрас (бо рӯйхати backend `/api/v1/models` мувофиқ).
class AIModel {
  final String id;
  final String name;
  final String desc;
  const AIModel(this.id, this.name, this.desc);

  static const List<AIModel> all = [
    AIModel('Qwen/Qwen3-8B', 'Superior Fast', 'Зуд ва сабук'),
    AIModel('Qwen/Qwen2.5-72B-Instruct', 'Superior Pro',
        'Қавитар, барои масъалаҳои мураккаб'),
    AIModel('Qwen/Qwen2.5-Coder-32B-Instruct', 'Superior Coder',
        'Махсус барои коднависӣ'),
    AIModel('deepseek-ai/DeepSeek-R1', 'Superior Think',
        'Тафаккури амиқ ва мантиқӣ'),
  ];

  static AIModel byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => all.first);
}
