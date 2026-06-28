import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _controller = TextEditingController();
  String _result = '';
  bool _loading = false;
  String _target = 'ru';

  final _langs = {'ru': '🇷🇺 Русӣ', 'en': '🇬🇧 Англисӣ', 'tg': '🇹🇯 Тоҷикӣ'};

  Future<void> _translate() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() { _loading = true; _result = ''; });
    final r = await AIService.translate(_controller.text.trim(), _target);
    setState(() { _result = r; _loading = false; });
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
        title: const Text('🌐 Тарҷума',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Lang selector
            Row(
              children: _langs.entries.map((e) {
                final sel = e.key == _target;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _target = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFF10A37F)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel
                                ? const Color(0xFF10A37F)
                                : const Color(0xFF2A2A2A)),
                      ),
                      child: Text(e.value,
                          style: TextStyle(
                              color: sel ? Colors.white : const Color(0xFF8E8EA0),
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Input
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              padding: const EdgeInsets.all(14),
              child: EditableText(
                controller: _controller,
                focusNode: FocusNode(),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                cursorColor: const Color(0xFF10A37F),
                backgroundCursorColor: Colors.grey,
                maxLines: 5,
                minLines: 3,
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _translate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10A37F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Тарҷума кун',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
              ),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10A37F).withOpacity(0.3)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_result,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, height: 1.5)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _result));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Нусха гирифта шуд'),
                              backgroundColor: Color(0xFF10A37F),
                              duration: Duration(seconds: 1)),
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, color: Color(0xFF8E8EA0), size: 14),
                          SizedBox(width: 4),
                          Text('Нусха',
                              style: TextStyle(
                                  color: Color(0xFF8E8EA0), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
