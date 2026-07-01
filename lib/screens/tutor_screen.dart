import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

/// Superior Teacher — чати таълимии интерактивӣ (режими teach).
/// [lessonContext] — матни дарс (ихтиёрӣ); [opening] — паёми аввали худкор.
class TutorScreen extends StatefulWidget {
  final String title;
  final String? lessonContext;
  final String? opening;

  const TutorScreen({
    super.key,
    this.title = 'Superior Teacher',
    this.lessonContext,
    this.opening,
  });

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  // модели қавитар барои таълими беҳтар
  static const _teachModel = 'Qwen/Qwen2.5-72B-Instruct';

  final List<ChatMessage> _messages = [];
  final ScrollController _scroll = ScrollController();
  bool _isStreaming = false;
  StreamSubscription<String>? _sub;

  @override
  void initState() {
    super.initState();
    if (widget.opening != null && widget.opening!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.opening!));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  String? get _system {
    if (widget.lessonContext == null || widget.lessonContext!.trim().isEmpty) {
      return null;
    }
    return 'You are teaching this specific lesson. '
        'Teach it interactively, step by step.\n\n${widget.lessonContext}';
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
      _teachModel,
      mode: 'teach',
      system: _system,
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
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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

  Widget _buildEmpty() {
    final ideas = [
      'Ин мавзӯъро ба ман содда фаҳмон',
      'Бо мисоли ҳаётӣ шарҳ деҳ',
      'Маро санҷ (quiz)',
      'Қадам ба қадам ёд деҳ',
    ];
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
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Superior Teacher',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Ҳар чизро ба шумо ёд медиҳам — қадам ба қадам',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8E8EA0), fontSize: 14)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: ideas
                  .map((s) => GestureDetector(
                        onTap: () => _send(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF171717),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: Text(s,
                              style: const TextStyle(
                                  color: Color(0xFFCACACA), fontSize: 13)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
