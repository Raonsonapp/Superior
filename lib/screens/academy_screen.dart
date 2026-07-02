import 'package:flutter/material.dart';
import '../models/academy.dart';
import '../theme.dart';
import 'lesson_screen.dart';
import 'tutor_screen.dart';

/// Superior AI Academy — рӯйхати курсҳо (volume-ҳо ва қисмҳо).
class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  static IconData _iconFor(String topic) {
    final t = topic.toLowerCase();
    if (t.contains('python')) return Icons.code;
    if (t.contains('recursion')) return Icons.repeat;
    if (t.contains('sort')) return Icons.sort;
    if (t.contains('architecture')) return Icons.account_tree_outlined;
    if (t.contains('database') || t.contains('sql')) return Icons.storage;
    if (t.contains('system design')) return Icons.hub_outlined;
    if (t.contains('oop') || t.contains('object')) return Icons.category_outlined;
    if (t.contains('data') || t.contains('science')) return Icons.analytics_outlined;
    if (t.contains('backend')) return Icons.dns_outlined;
    if (t.contains('flutter') || t.contains('full')) return Icons.phone_iphone;
    if (t.contains('model') || t.contains('engineering')) return Icons.smart_toy_outlined;
    if (t.contains('startup') || t.contains('product')) return Icons.rocket_launch_outlined;
    if (t.contains('capstone')) return Icons.emoji_events_outlined;
    if (t.contains('function')) return Icons.functions;
    if (t.contains('condition') || t.contains('loop')) return Icons.loop;
    if (t.contains('file') || t.contains('json')) return Icons.folder_outlined;
    return Icons.menu_book_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Superior Academy'),
      ),
      body: FutureBuilder<List<Course>>(
        future: Course.loadAll(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = snap.data ?? [];
          if (courses.isEmpty) {
            return const Center(
              child: Text('Курс бор нашуд',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }
          final totalLessons = courses.fold<int>(
              0, (s, c) => s + c.parts.fold<int>(0, (x, p) => x + p.lessons.length));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _teacherBanner(context, totalLessons),
              const SizedBox(height: 24),
              for (final course in courses) ...[
                _volumeHeader(course),
                const SizedBox(height: 12),
                ...course.parts.map((p) => _partCard(context, p)),
                const SizedBox(height: 20),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _teacherBanner(BuildContext context, int totalLessons) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TutorScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.teacher, Color(0xFFEF4444)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.teacher.withOpacity(0.25),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Аз муаллим бипурс',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$totalLessons дарс • ҳама чизро ёд медиҳам',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _volumeHeader(Course c) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.teacher.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Volume ${c.volume}',
              style: const TextStyle(
                  color: AppColors.teacher,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            c.title.replaceFirst(RegExp(r'.*—\s*'), ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _partCard(BuildContext context, CoursePart p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LessonScreen(part: p)),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.teacher.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconFor(p.topic),
                      color: AppColors.teacher, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.topic,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text('${p.lessons.length} дарс • ${p.quiz.length} савол',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF4A4A4A)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
