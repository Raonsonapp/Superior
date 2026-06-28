import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final bool isLoading;
  final Function(String) onSend;

  const ChatInput({super.key, required this.isLoading, required this.onSend});

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
      setState(() => _hasText = _controller.text.trim().isNotEmpty);
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
    if (!_hasText || widget.isLoading) return;
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: EditableText(
                  controller: _controller,
                  focusNode: _focus,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  cursorColor: const Color(0xFF10A37F),
                  backgroundCursorColor: Colors.grey,
                  maxLines: 5,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: GestureDetector(
                onTap: _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (_hasText && !widget.isLoading)
                        ? const Color(0xFF10A37F)
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: widget.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF10A37F),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.arrow_upward_rounded,
                          color: _hasText ? Colors.white : const Color(0xFF4A4A4A),
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
