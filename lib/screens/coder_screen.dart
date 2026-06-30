import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

/// Superior Coder — режими махсуси коднависӣ.
/// Модели коднависиро (Qwen2.5-Coder) бо system prompt-и муҳандисӣ истифода мебарад.
class CoderScreen extends StatefulWidget {
  const CoderScreen({super.key});

  @override
  State<CoderScreen> createState() => _CoderScreenState();
}

class _CoderScreenState extends State<CoderScreen> {
  static const _coderModel = 'Qwen/Qwen2.5-Coder-32B-Instruct';

  final List<ChatMessage> _messages = [];
  final ScrollController _scroll = ScrollController();
  bool _isStreaming = false;
  StreamSubscription<String>? _sub;
  String _lang = 'Python';

  static const _languages = [
    'Python', 'Dart', 'Go', 'JavaScript', 'TypeScript',
    'Java', 'C++', 'Rust', 'SQL', 'Bash',
  ];

  // Намунаҳои омодаи дархост — бо забони интихобшуда.
  List<({String emoji, String label, String prompt})> get _examples => [
        (
          emoji: '📧',
          label: 'Санҷиши email',
          prompt:
              'Бо забони $_lang функсияе навис, ки санҷад оё сатр email-и дуруст аст. Тестҳо ҳам илова кун.'
        ),
        (
          emoji: '🔍',
          label: 'Binary search',
          prompt:
              'Алгоритми binary search-ро бо $_lang навис, бо шарҳи қадам ба қадам ва намунаи истифода.'
        ),
        (
          emoji: '🌐',
          label: 'REST API',
          prompt:
              'Як REST API-и оддии CRUD бо $_lang намуна нишон деҳ (бо тавзеҳи кӯтоҳ).'
        ),
        (
          emoji: '🐛',
          label: 'Хатогиҳои маъмул',
          prompt:
              '5 хатогии маъмули $_lang-ро бо мисоли код ва тарзи ислоҳашон фаҳмон.'
        ),
      ];

  @override
  void dispose() {
    _sub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isStreaming) return;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: text.trim(),
      role: 'user',
      timestamp: DateTime.now(),
    );
    final aiMsg = ChatMessage(
      id: '${DateTime.now().microsecondsSinceEpoch}_ai',
      content: '',
      role: 'assistant',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(aiMsg);
      _isStreaming = true;
    });
    _scrollToBottom();

    final history = _messages.where((m) => !m.isStreaming).toList();
    final buffer = StringBuffer();

    _sub = AIService.chatStream(
      history,
      _coderModel,
      mode: 'code',
      system: 'Default target language: $_lang.',
    ).listen(
      (chunk) {
        buffer.write(chunk);
        setState(() => aiMsg.content = buffer.toString());
        _scrollToBottom();
      },
      onDone: () {
        setState(() {
          aiMsg.isStreaming = false;
          if (buffer.isEmpty) {
            aiMsg.content = '⏳ Ҷавоб наомад. Лутфан дубора кӯшиш кунед.';
            aiMsg.isError = true;
          }
          _isStreaming = false;
        });
      },
      onError: (e) {
        setState(() {
          aiMsg.content = '❌ Хато: $e';
          aiMsg.isStreaming = false;
          aiMsg.isError = true;
          _isStreaming = false;
        });
      },
      cancelOnError: true,
    );
  }

  void _stop() {
    _sub?.cancel();
    if (_messages.isNotEmpty && _messages.last.isStreaming) {
      setState(() {
        _messages.last.isStreaming = false;
        _isStreaming = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.terminal, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Superior Coder',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Аз нав',
              onPressed: () => setState(() => _messages.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildLangBar(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => MessageBubble(
                      message: _messages[i],
                      onCopy: () {
                        Clipboard.setData(
                            ClipboardData(text: _messages[i].content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Нусха гирифта шуд'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Color(0xFF10A37F),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          ChatInput(isStreaming: _isStreaming, onSend: _send, onStop: _stop),
        ],
      ),
    );
  }

  Widget _buildLangBar() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        itemCount: _languages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final l = _languages[i];
          final sel = l == _lang;
          return GestureDetector(
            onTap: () => setState(() => _lang = l),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF6366F1) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF2A2A2A)),
              ),
              child: Text(l,
                  style: TextStyle(
                      color: sel ? Colors.white : const Color(0xFF8E8EA0),
                      fontSize: 13,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.terminal, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Superior Coder',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Ёрирасони коднависӣ • $_lang',
                style: const TextStyle(color: Color(0xFF8E8EA0), fontSize: 14)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _examples.map((a) {
                return GestureDetector(
                  onTap: () => _send(a.prompt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF171717),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(a.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(a.label,
                            style: const TextStyle(
                                color: Color(0xFFCACACA), fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Кодатонро барои debug/шарҳ part кунед,\nё як дархост бо забони интихобшуда нависед.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6A6A6A), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
