import 'package:flutter/material.dart';
import '../models/academy.dart';
import 'lesson_screen.dart';
import 'tutor_screen.dart';

/// Superior AI Academy — рӯйхати курсҳо (қисмҳо).
class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  static const _icons = {
    'Recursion': Icons.repeat,
    'Sorting Algorithms': Icons.sort,
    'Software Architecture': Icons.account_tree_outlined,
    'Database Fundamentals': Icons.storage,
    'System Design Fundamentals': Icons.hub_outlined,
  };

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
        title: const Text('Superior Academy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<Course>(
        future: Course.load(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
            );
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(
              child: Text('Курс бор нашуд',
                  style: TextStyle(color: Color(0xFF8E8EA0))),
            );
          }
          final course = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTeacherBanner(context),
              const SizedBox(height: 20),
              Text('${course.title} • ${course.parts.length} мавзӯъ',
                  style: const TextStyle(
                      color: Color(0xFF8E8EA0),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...course.parts.map((p) => _buildPartCard(context, p)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeacherBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TutorScreen(
            title: 'Superior Teacher',
            opening: null,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.school, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Аз муаллим бипурс',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Ҳар мавзӯъро ба шумо ёд медиҳам',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildPartCard(BuildContext context, CoursePart p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LessonScreen(part: p)),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF171717),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icons[p.topic] ?? Icons.menu_book,
                    color: const Color(0xFFF59E0B), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.topic,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      p.goal.isEmpty
                          ? '${p.lessons.length} дарс'
                          : p.goal,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF8E8EA0), fontSize: 13, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text('${p.lessons.length} дарс • ${p.quiz.length} савол',
                        style: const TextStyle(
                            color: Color(0xFF6A6A6A), fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Color(0xFF4A4A4A), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
