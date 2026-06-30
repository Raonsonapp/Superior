import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final bool isStreaming;
  final Function(String) onSend;
  final VoidCallback? onStop;

  const ChatInput({
    super.key,
    required this.isStreaming,
    required this.onSend,
    this.onStop,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    if (!_hasText || widget.isStreaming) return;
    final text = _controller.text.trim();
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focus.hasFocus
                ? const Color(0xFF10A37F).withOpacity(0.5)
                : const Color(0xFF2A2A2A),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: const Color(0xFF10A37F),
                  maxLines: 6,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Паём нависед…',
                    hintStyle: TextStyle(color: Color(0xFF6A6A6A)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: GestureDetector(
                onTap: widget.isStreaming ? widget.onStop : _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.isStreaming
                        ? Colors.white
                        : (_hasText
                            ? const Color(0xFF10A37F)
                            : const Color(0xFF2A2A2A)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.isStreaming
                        ? Icons.stop_rounded
                        : Icons.arrow_upward_rounded,
                    color: widget.isStreaming
                        ? Colors.black
                        : (_hasText ? Colors.white : const Color(0xFF4A4A4A)),
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
