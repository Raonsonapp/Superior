import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import 'features_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _chatCount = 1;

  @override
  void initState() {
    super.initState();
    _addWelcome();
  }

  void _addWelcome() {
    _messages.add(ChatMessage(
      id: 'w',
      content: 'Салом! Ман Superior AI ҳастам. Чӣ хел кӯмак карда метавонам?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text.trim(),
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messages.add(ChatMessage(
        id: 'loading',
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        isLoading: true,
      ));
      _isLoading = true;
    });
    _scrollToBottom();

    final reply = await AIService.chat(text.trim());

    setState(() {
      _messages.removeWhere((m) => m.id == 'loading');
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _chatCount++;
      _addWelcome();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSidebar() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171717),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10A37F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text('Superior AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.add_comment_outlined, color: Colors.white),
              title: const Text('Чат нав', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _newChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.apps_outlined, color: Colors.white),
              title: const Text('Функсияҳо', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const FeaturesScreen()));
              },
            ),
            const Divider(color: Color(0xFF2A2A2A)),
            Expanded(
              child: ListView.builder(
                itemCount: _chatCount,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.chat_bubble_outline,
                      color: Color(0xFF8E8EA0), size: 18),
                  title: Text(
                    'Чат ${_chatCount - i}',
                    style: const TextStyle(color: Color(0xFF8E8EA0), fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: _showSidebar,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Superior AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: const Text(
                'Qwen 3',
                style: TextStyle(color: Color(0xFF8E8EA0), fontSize: 11),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            onPressed: _newChat,
            tooltip: 'Чат нав',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scrollController,
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
          ChatInput(isLoading: _isLoading, onSend: _send),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF10A37F).withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Color(0xFF10A37F), size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Superior AI',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Чи хел кӯмак карда метавонам?',
              style: TextStyle(color: Color(0xFF8E8EA0), fontSize: 14)),
        ],
      ),
    );
  }
}
