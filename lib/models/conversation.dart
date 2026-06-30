import 'chat_message.dart';

/// Як гуфтугӯ — маҷмӯи паёмҳо бо унвон, модел ва вақт.
class Conversation {
  final String id;
  String title;
  String model;
  final DateTime createdAt;
  DateTime updatedAt;
  List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.model,
    required this.createdAt,
    required this.updatedAt,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  factory Conversation.create(String model) {
    final now = DateTime.now();
    return Conversation(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'Чати нав',
      model: model,
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
  }

  /// Унвонро аз аввалин паёми корбар месозад.
  void deriveTitle() {
    final firstUser = messages.where((m) => m.isUser).firstOrNull;
    if (firstUser != null && firstUser.content.trim().isNotEmpty) {
      final t = firstUser.content.trim().replaceAll('\n', ' ');
      title = t.length > 38 ? '${t.substring(0, 38)}…' : t;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'model': model,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Чат',
        model: json['model'] as String? ?? 'Qwen/Qwen3-8B',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        messages: (json['messages'] as List<dynamic>? ?? [])
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
