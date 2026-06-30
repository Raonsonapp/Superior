/// Як паёми чат — аз корбар ё аз ассистент.
class ChatMessage {
  final String id;
  String content;
  final String role; // 'user' | 'assistant'
  final DateTime timestamp;
  bool isStreaming;
  bool isError;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isStreaming = false,
    this.isError = false,
  });

  bool get isUser => role == 'user';

  ChatMessage copyWith({String? content, bool? isStreaming, bool? isError}) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      role: role,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': role,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        content: json['content'] as String,
        role: json['role'] as String? ?? 'assistant',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );

  /// Барои ирсол ба backend (формати OpenAI/HF).
  Map<String, String> toApi() => {'role': role, 'content': content};
}
