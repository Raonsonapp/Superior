import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

enum ChatMode { chat, translate, summarize, code, improve }

class ChatScreen extends StatefulWidget {
  final ChatMode mode;
  const ChatScreen({super.key, required this.mode});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _selectedLang = 'ru';

  // Chat history барои multi-turn
  final List<Map<String, String>> _history = [];

  String get _title {
    switch (widget.mode) {
      case ChatMode.chat: return '💬 AI Chat';
      case ChatMode.translate: return '🌐 Тарҷума';
      case ChatMode.summarize: return '📝 Хулоса';
      case ChatMode.code: return '💻 Код';
      case ChatMode.improve: return '✍️ Матн';
    }
  }

  String get _placeholder {
    switch (widget.mode) {
      case ChatMode.chat: return 'Паёми худро бинавис...';
      case ChatMode.translate: return 'Матни тарҷумашавандаро бинавис...';
      case ChatMode.summarize: return 'Матни дарозро барои хулоса бинавис...';
      case ChatMode.code: return 'Кодро барои ислоҳ бинавис...';
      case ChatMode.improve: return 'Матнро барои беҳтар кардан бинавис...';
    }
  }

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(ChatMessage(
      id: 'welcome',
      content: _getWelcomeMessage(),
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  String _getWelcomeMessage() {
    switch (widget.mode) {
      case ChatMode.chat:
        return '👋 Салом! Ман Superior AI ҳастам, бо Qwen 3 кор мекунам.\n\nЧӣ хел кӯмак карда метавонам?';
      case ChatMode.translate:
        return '🌐 Тарҷумон тайёр аст!\n\nЗабонро интихоб кун ва матнро бинавис.';
      case ChatMode.summarize:
        return '📝 Матнатро бинавис — ман онро дар 3-5 ҷумла хулоса мекунам.';
      case ChatMode.code:
        return '💻 Кодатро бинавис — ман хатоҳоро меёбам ва ислоҳ мекунам.';
      case ChatMode.improve:
        return '✍️ Матнатро бинавис — ман услуб ва грамматикаро беҳтар мекунам.';
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    final loadingMsg = ChatMessage(
      id: 'loading',
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(loadingMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    String response;
    try {
      switch (widget.mode) {
        case ChatMode.chat:
          response = await AIService.chat(text, history: _history);
          _history.add({'role': 'user', 'content': text});
          _history.add({'role': 'assistant', 'content': response});
          // Тарихро 10 паём маҳдуд мекунем
          if (_history.length > 20) {
            _history.removeRange(0, 2);
          }
          break;
        case ChatMode.translate:
          response = await AIService.translate(text, _selectedLang);
          break;
        case ChatMode.summarize:
          response = await AIService.summarize(text);
          break;
        case ChatMode.code:
          response = await AIService.fixCode(text);
          break;
        case ChatMode.improve:
          response = await AIService.improveText(text);
          break;
      }
    } catch (e) {
      response = '❌ Хатогӣ: $e';
    }

    setState(() {
      _messages.remove(loadingMsg);
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
    });

    _scrollToBottom();
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

  void _clearChat() {
    setState(() {
      _messages.clear();
      _history.clear();
      _messages.add(ChatMessage(
        id: 'welcome',
        content: _getWelcomeMessage(),
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Тугмаи New Chat — ЗАКРЕПЛЁН дар боло
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            tooltip: 'Чат нав',
            onPressed: _clearChat,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Language selector барои translate mode
          if (widget.mode == ChatMode.translate) _buildLangSelector(),

          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubble(
                        message: _messages[index],
                        onCopy: () {
                          Clipboard.setData(
                            ClipboardData(text: _messages[index].content),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Нусха гирифта шуд'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // Input field — ЗАКРЕПЛЁН дар поён
          ChatInput(
            placeholder: _placeholder,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildLangSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          const Text('Ба:', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 12),
          _LangBtn(label: '🇷🇺 Русӣ', value: 'ru', selected: _selectedLang,
              onTap: () => setState(() => _selectedLang = 'ru')),
          const SizedBox(width: 8),
          _LangBtn(label: '🇬🇧 Англисӣ', value: 'en', selected: _selectedLang,
              onTap: () => setState(() => _selectedLang = 'en')),
          const SizedBox(width: 8),
          _LangBtn(label: '🇹🇯 Тоҷикӣ', value: 'tg', selected: _selectedLang,
              onTap: () => setState(() => _selectedLang = 'tg')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 48),
          SizedBox(height: 12),
          Text('Чат холӣ аст', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_comment_outlined, color: Colors.white),
              title: const Text('Чат нав', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Тарих тоза', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LangBtn extends StatelessWidget {
  final String label, value, selected;
  final VoidCallback onTap;
  const _LangBtn({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
