import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';

/// Контенти паёмро рендер мекунад: матни Markdown + блокҳои код бо
/// syntax highlighting ва тугмаи нусхабардорӣ (мисли ChatGPT).
class MessageContent extends StatelessWidget {
  final String text;
  const MessageContent(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final segments = _parse(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((s) {
        if (s.isCode) {
          return _CodeBlock(code: s.content, language: s.language);
        }
        if (s.content.trim().isEmpty) return const SizedBox.shrink();
        return MarkdownBody(
          data: s.content,
          selectable: true,
          styleSheet: _markdownStyle(context),
        );
      }).toList(),
    );
  }

  static MarkdownStyleSheet _markdownStyle(BuildContext context) {
    return MarkdownStyleSheet(
      p: const TextStyle(color: Color(0xFFECECEC), fontSize: 15, height: 1.6),
      h1: const TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      h2: const TextStyle(
          color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
      h3: const TextStyle(
          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
      listBullet:
          const TextStyle(color: Color(0xFFECECEC), fontSize: 15, height: 1.6),
      strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      em: const TextStyle(color: Color(0xFFECECEC), fontStyle: FontStyle.italic),
      code: const TextStyle(
        color: Color(0xFF10D9A0),
        backgroundColor: Color(0xFF1E1E1E),
        fontFamily: 'monospace',
        fontSize: 14,
      ),
      codeblockDecoration: const BoxDecoration(),
      blockquote: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 15),
      blockquoteDecoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: const Border(left: BorderSide(color: Color(0xFF10A37F), width: 3)),
        borderRadius: BorderRadius.circular(4),
      ),
      a: const TextStyle(color: Color(0xFF10A37F)),
      tableBody:
          const TextStyle(color: Color(0xFFECECEC), fontSize: 14),
      tableBorder: TableBorder.all(color: const Color(0xFF2A2A2A)),
      tableHead: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  /// Матнро ба қисмҳои матнӣ ва код (```lang ... ```) ҷудо мекунад.
  static List<_Segment> _parse(String input) {
    final segments = <_Segment>[];
    final regex = RegExp(r'```(\w*)\n?([\s\S]*?)```', multiLine: true);
    int last = 0;
    for (final m in regex.allMatches(input)) {
      if (m.start > last) {
        segments.add(_Segment(input.substring(last, m.start), false, ''));
      }
      final lang = (m.group(1) ?? '').trim();
      final code = m.group(2) ?? '';
      segments.add(_Segment(code.trimRight(), true, lang));
      last = m.end;
    }
    if (last < input.length) {
      segments.add(_Segment(input.substring(last), false, ''));
    }
    if (segments.isEmpty) segments.add(_Segment(input, false, ''));
    return segments;
  }
}

class _Segment {
  final String content;
  final bool isCode;
  final String language;
  _Segment(this.content, this.isCode, this.language);
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final String language;
  const _CodeBlock({required this.code, required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: забон + тугмаи нусха
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0E0E0E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Text(
                  language.isEmpty ? 'код' : language,
                  style: const TextStyle(
                      color: Color(0xFF8E8EA0), fontSize: 12),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Код нусха гирифта шуд'),
                        duration: Duration(seconds: 1),
                        backgroundColor: Color(0xFF10A37F),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.copy_outlined,
                          size: 13, color: Color(0xFF8E8EA0)),
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
          // Код
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              code,
              language: _safeLang(language),
              theme: atomOneDarkTheme,
              padding: const EdgeInsets.all(14),
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // забонҳои маъмул; агар номаълум бошад — text.
  static String _safeLang(String lang) {
    const known = {
      'dart', 'go', 'python', 'py', 'javascript', 'js', 'typescript', 'ts',
      'java', 'kotlin', 'swift', 'c', 'cpp', 'csharp', 'cs', 'php', 'ruby',
      'rust', 'sql', 'html', 'css', 'json', 'yaml', 'bash', 'shell', 'sh',
      'xml', 'markdown', 'md',
    };
    final l = lang.toLowerCase();
    if (l == 'py') return 'python';
    if (l == 'js') return 'javascript';
    if (l == 'ts') return 'typescript';
    if (l == 'sh') return 'bash';
    return known.contains(l) ? l : 'plaintext';
  }
}
