import 'package:flutter/material.dart';
import '../models/academy.dart';
import '../widgets/message_content.dart';
import 'tutor_screen.dart';

/// Экрани як мавзӯъ — дарсҳо, тест ва тугмаи «муаллим ба ман ёд диҳад».
class LessonScreen extends StatelessWidget {
  final CoursePart part;
  const LessonScreen({super.key, required this.part});

  void _teach(BuildContext context, {String? opening}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TutorScreen(
          title: part.topic,
          lessonContext: part.toContext(),
          opening: opening,
        ),
      ),
    );
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
        title: Text(part.topic,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (part.goal.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.flag_outlined,
                      color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(part.goal,
                        style: const TextStyle(
                            color: Color(0xFFECECEC),
                            fontSize: 14,
                            height: 1.4)),
                  ),
                ],
              ),
            ),

          // Дарсҳо
          ...part.lessons.asMap().entries.map((e) {
            final i = e.key;
            final l = e.value;
            return _LessonCard(index: i + 1, lesson: l);
          }),

          // Тест
          if (part.quiz.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Тест',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...part.quiz.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${e.key + 1}. ${e.value}',
                      style: const TextStyle(
                          color: Color(0xFFCACACA),
                          fontSize: 14,
                          height: 1.4)),
                )),
          ],

          const SizedBox(height: 20),

          // Тугмаҳои амал
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _teach(context,
                      opening: 'Ин дарсро ба ман ёд деҳ: «${part.topic}». '
                          'Аз асосҳо сар кун ва қадам ба қадам фаҳмон.'),
                  icon: const Icon(Icons.school, size: 18),
                  label: const Text('Ба ман ёд деҳ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _teach(context,
                      opening: 'Маро аз мавзӯи «${part.topic}» санҷ. '
                          'Як савол деҳ ва ҷавоби маро санҷ.'),
                  icon: const Icon(Icons.quiz_outlined, size: 18),
                  label: const Text('Маро санҷ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatefulWidget {
  final int index;
  final Lesson lesson;
  const _LessonCard({required this.index, required this.lesson});

  @override
  State<_LessonCard> createState() => _LessonCardState();
}

class _LessonCardState extends State<_LessonCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${widget.index}',
                        style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.lesson.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ),
                  Icon(_open ? Icons.expand_less : Icons.expand_more,
                      color: const Color(0xFF8E8EA0)),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: MessageContent(widget.lesson.body),
            ),
        ],
      ),
    );
  }
}
