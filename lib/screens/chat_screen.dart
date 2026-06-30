import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import 'features_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scroll = ScrollController();
  List<Conversation> _conversations = [];
  Conversation? _current;
  String _model = 'Qwen/Qwen3-8B';
  bool _isStreaming = false;
  StreamSubscription<String>? _sub;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final model = await StorageService.loadModel();
    final convs = await StorageService.loadConversations();
    setState(() {
      _model = model;
      _conversations = convs;
      _current = convs.isNotEmpty ? convs.first : Conversation.create(model);
      _loaded = true;
    });
  }

  List<ChatMessage> get _messages => _current?.messages ?? [];

  Future<void> _persist() async {
    if (_current == null) return;
    _current!.updatedAt = DateTime.now();
    // ҳамеша гуфтугӯи ҷориро дар рӯйхат нигоҳ медорем
    _conversations.removeWhere((c) => c.id == _current!.id);
    if (_current!.messages.isNotEmpty) {
      _conversations.insert(0, _current!);
    }
    await StorageService.saveConversations(_conversations);
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isStreaming || _current == null) return;

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
      _current!.messages.add(userMsg);
      _current!.messages.add(aiMsg);
      if (_current!.messages.where((m) => m.isUser).length == 1) {
        _current!.deriveTitle();
      }
      _isStreaming = true;
    });
    _scrollToBottom();
    await _persist();

    // таърих барои backend (бе паёми streaming-и холӣ)
    final history =
        _current!.messages.where((m) => !(m.isStreaming)).toList();

    final buffer = StringBuffer();
    _sub = AIService.chatStream(history, _model).listen(
      (chunk) {
        buffer.write(chunk);
        setState(() => aiMsg.content = buffer.toString());
        _scrollToBottom();
      },
      onDone: () async {
        setState(() {
          aiMsg.isStreaming = false;
          if (buffer.isEmpty) {
            aiMsg.content = '⏳ Ҷавоб наомад. Лутфан дубора кӯшиш кунед.';
            aiMsg.isError = true;
          }
          _isStreaming = false;
        });
        await _persist();
      },
      onError: (e) async {
        setState(() {
          aiMsg.content = '❌ Хато: $e';
          aiMsg.isStreaming = false;
          aiMsg.isError = true;
          _isStreaming = false;
        });
        await _persist();
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
      _persist();
    }
  }

  Future<void> _regenerate() async {
    if (_isStreaming || _current == null) return;
    // паёми охирини ассистентро мепартоем ва аз нав мепурсем
    final msgs = _current!.messages;
    if (msgs.isEmpty) return;
    if (!msgs.last.isUser) {
      msgs.removeLast();
    }
    if (msgs.isEmpty || !msgs.last.isUser) return;
    final lastUser = msgs.removeLast();
    setState(() {});
    await _send(lastUser.content);
  }

  void _newChat() {
    _stop();
    setState(() {
      _current = Conversation.create(_model);
    });
    Navigator.maybePop(context);
  }

  void _openConversation(Conversation c) {
    _stop();
    setState(() => _current = c);
    Navigator.maybePop(context);
  }

  Future<void> _deleteConversation(Conversation c) async {
    setState(() {
      _conversations.removeWhere((x) => x.id == c.id);
      if (_current?.id == c.id) {
        _current = _conversations.isNotEmpty
            ? _conversations.first
            : Conversation.create(_model);
      }
    });
    await StorageService.saveConversations(_conversations);
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

  void _pickModel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171717),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text('Моделро интихоб кунед',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            ...AIModel.all.map((m) {
              final sel = m.id == _model;
              return ListTile(
                leading: Icon(
                  sel ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: sel ? const Color(0xFF10A37F) : const Color(0xFF6A6A6A),
                ),
                title: Text(m.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(m.desc,
                    style: const TextStyle(color: Color(0xFF8E8EA0))),
                onTap: () async {
                  setState(() => _model = m.id);
                  if (_current != null) _current!.model = m.id;
                  await StorageService.saveModel(m.id);
                  if (mounted) Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF10A37F)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        title: GestureDetector(
          onTap: _pickModel,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Superior AI',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AIModel.byId(_model).name,
                        style: const TextStyle(
                            color: Color(0xFF8E8EA0), fontSize: 11)),
                    const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFF8E8EA0), size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            onPressed: _newChat,
            tooltip: 'Чати нав',
          ),
        ],
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
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final isLastAi = !m.isUser &&
                          i == _messages.length - 1 &&
                          !m.isStreaming;
                      return MessageBubble(
                        message: m,
                        onCopy: () {
                          Clipboard.setData(ClipboardData(text: m.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Нусха гирифта шуд'),
                              duration: Duration(seconds: 1),
                              backgroundColor: Color(0xFF10A37F),
                            ),
                          );
                        },
                        onRegenerate: isLastAi ? _regenerate : null,
                      );
                    },
                  ),
          ),
          ChatInput(
            isStreaming: _isStreaming,
            onSend: _send,
            onStop: _stop,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final suggestions = [
      ('💻', 'Як функсияи Python барои санҷиши email нависед'),
      ('🌐', 'Калимаи «салом»-ро ба 5 забон тарҷума кун'),
      ('📝', 'Як нақшаи кории ҳафтаина барои ман соз'),
      ('🧠', 'Фарқи AI ва Machine Learning чист?'),
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
                  colors: [Color(0xFF10A37F), Color(0xFF1A7F64)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            const Text('Superior AI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Чӣ хел кӯмак карда метавонам?',
                style: TextStyle(color: Color(0xFF8E8EA0), fontSize: 15)),
            const SizedBox(height: 28),
            ...suggestions.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _send(s.$2),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF171717),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          Text(s.$1, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(s.$2,
                                style: const TextStyle(
                                    color: Color(0xFFCACACA), fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10A37F), Color(0xFF1A7F64)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text('Superior AI',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading:
                    const Icon(Icons.add_comment_outlined, color: Colors.white),
                title: const Text('Чати нав',
                    style: TextStyle(color: Colors.white)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: _newChat,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListTile(
                leading: const Icon(Icons.apps_outlined, color: Colors.white),
                title: const Text('Функсияҳо',
                    style: TextStyle(color: Colors.white)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FeaturesScreen()),
                  );
                },
              ),
            ),
            const Divider(color: Color(0xFF2A2A2A)),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('Таърих',
                  style: TextStyle(
                      color: Color(0xFF6A6A6A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: _conversations.isEmpty
                  ? const Center(
                      child: Text('Ҳанӯз гуфтугӯе нест',
                          style: TextStyle(color: Color(0xFF6A6A6A))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: _conversations.length,
                      itemBuilder: (_, i) {
                        final c = _conversations[i];
                        final sel = c.id == _current?.id;
                        return ListTile(
                          dense: true,
                          selected: sel,
                          selectedTileColor: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          leading: const Icon(Icons.chat_bubble_outline,
                              color: Color(0xFF8E8EA0), size: 18),
                          title: Text(
                            c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : const Color(0xFFCACACA),
                                fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Color(0xFF6A6A6A), size: 18),
                            onPressed: () => _deleteConversation(c),
                          ),
                          onTap: () => _openConversation(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
