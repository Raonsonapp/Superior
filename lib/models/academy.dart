import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Як дарс (section) дар дохили як қисми курс.
class Lesson {
  final String title;
  final String body;
  const Lesson({required this.title, required this.body});

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
      );
}

/// Як қисми курс — як мавзӯъ бо дарсҳо ва тест.
class CoursePart {
  final int id;
  final String topic;
  final String goal;
  final List<Lesson> lessons;
  final List<String> quiz;

  const CoursePart({
    required this.id,
    required this.topic,
    required this.goal,
    required this.lessons,
    required this.quiz,
  });

  factory CoursePart.fromJson(Map<String, dynamic> j) => CoursePart(
        id: j['id'] as int? ?? 0,
        topic: j['topic'] as String? ?? '',
        goal: j['goal'] as String? ?? '',
        lessons: (j['sections'] as List<dynamic>? ?? [])
            .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
            .toList(),
        quiz: (j['quiz'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );

  /// Матни пурраи қисм — барои контексти муаллим (system prompt).
  String toContext() {
    final b = StringBuffer();
    b.writeln('LESSON TOPIC: $topic');
    if (goal.isNotEmpty) b.writeln('GOAL: $goal');
    b.writeln();
    for (final l in lessons) {
      b.writeln('## ${l.title}');
      b.writeln(l.body);
      b.writeln();
    }
    if (quiz.isNotEmpty) {
      b.writeln('QUIZ QUESTIONS:');
      for (var i = 0; i < quiz.length; i++) {
        b.writeln('${i + 1}. ${quiz[i]}');
      }
    }
    return b.toString();
  }
}

/// Курс (Volume) — маҷмӯи қисмҳо.
class Course {
  final int volume;
  final String title;
  final List<CoursePart> parts;

  const Course({
    required this.volume,
    required this.title,
    required this.parts,
  });

  static Course? _cache;

  /// Курсро аз asset-и JSON бор мекунад (як маротиба cache мешавад).
  static Future<Course> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/academy/volume1.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final course = Course(
      volume: j['volume'] as int? ?? 1,
      title: j['title'] as String? ?? 'Superior AI Academy',
      parts: (j['parts'] as List<dynamic>? ?? [])
          .map((e) => CoursePart.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    _cache = course;
    return course;
  }
}
