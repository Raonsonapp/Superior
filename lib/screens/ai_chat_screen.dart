import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await AIService.chat(text);
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': '❌ Хатогӣ: $e'});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI Chat — Qwen 3'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF16213E),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF0F3460)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUser
                            ? const Color(0xFF533483)
                            : const Color(0xFF0F3460),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF533483),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('AI фикр мекунад...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1A1A2E),
            child: Row(
              children: [
                Expanded(
                  child: EditableText(
                    controller: _controller,
                    focusNode: FocusNode(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    cursorColor: const Color(0xFF533483),
                    backgroundCursorColor: Colors.grey,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3460),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF533483),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
