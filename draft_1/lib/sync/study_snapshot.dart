import 'dart:convert';

import 'package:draft_1/globals.dart' as globals;
import 'package:draft_1/model.dart';
import 'package:draft_1/study_analytics.dart';

/// A point-in-time, serialisable copy of all of the user's study data: their
/// tests, the per-day task lists, flashcard decks and logged study sessions.
///
/// A snapshot is the unit of both local persistence and cloud backup. It is a
/// plain data object — it does not touch the global stores itself. Use
/// [StudySnapshot.capture] to read the current in-memory state into a snapshot
/// and [restore] to push a snapshot back into the live stores.
class StudySnapshot {
  /// Bumped when the on-the-wire shape changes so older payloads can be
  /// migrated (or rejected) rather than misread.
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final List<Test> tests;
  final Map<DateTime, List<Task>> tasksByDate;
  final List<Deck> decks;
  final List<StudySession> sessions;

  const StudySnapshot({
    required this.tests,
    required this.tasksByDate,
    required this.decks,
    required this.sessions,
    this.schemaVersion = currentSchemaVersion,
  });

  /// Reads the current in-memory study data into an immutable snapshot.
  factory StudySnapshot.capture() => StudySnapshot(
        tests: List.of(globals.tests),
        tasksByDate: {
          for (final entry in globals.tasksByDate.entries)
            entry.key: List.of(entry.value),
        },
        decks: List.of(globals.decks),
        sessions: List.of(StudyAnalytics.instance.sessions),
      );

  bool get isEmpty =>
      tests.isEmpty &&
      tasksByDate.isEmpty &&
      decks.isEmpty &&
      sessions.isEmpty;

  /// Replaces the live in-memory stores with the contents of this snapshot.
  /// Called on startup (loading the local copy) and when restoring a backup.
  void restore() {
    globals.tests
      ..clear()
      ..addAll(tests);
    globals.tasksByDate
      ..clear()
      ..addAll({
        for (final entry in tasksByDate.entries)
          entry.key: List.of(entry.value),
      });
    globals.decks
      ..clear()
      ..addAll(decks);
    StudyAnalytics.instance.replaceSessions(sessions);
  }

  /// Combines two snapshots into one that contains the union of both, used to
  /// reconcile a true conflict (the local copy and the cloud copy were both
  /// edited since they last agreed) without losing data:
  ///   * tests and sessions are unioned, dropping byte-for-byte duplicates;
  ///   * decks are merged by name, unioning their cards;
  ///   * tasks are merged per day, deduped by name, and a task counts as done
  ///     if it was completed in either copy.
  ///
  /// This favours keeping data over collapsing it: an item edited differently
  /// on two devices may appear twice rather than silently losing one edit.
  static StudySnapshot merge(StudySnapshot a, StudySnapshot b) {
    String key(Object json) => jsonEncode(json);

    // Tests — union by full content.
    final tests = <Test>[];
    final seenTests = <String>{};
    for (final test in [...a.tests, ...b.tests]) {
      if (seenTests.add(key(test.toJson()))) tests.add(test);
    }

    // Sessions — union by full content.
    final sessions = <StudySession>[];
    final seenSessions = <String>{};
    for (final session in [...a.sessions, ...b.sessions]) {
      if (seenSessions.add(key(session.toJson()))) sessions.add(session);
    }

    // Decks — merge by name, unioning cards within a deck.
    final decksByName = <String, Deck>{};
    for (final deck in [...a.decks, ...b.decks]) {
      final target = decksByName.putIfAbsent(deck.name, () => Deck(name: deck.name));
      final seenCards = {for (final c in target.cards) key(c.toJson())};
      for (final card in deck.cards) {
        if (seenCards.add(key(card.toJson()))) target.cards.add(card);
      }
    }

    // Tasks — merge per day, dedupe by name, OR the completion flag.
    final tasksByDate = <DateTime, List<Task>>{};
    for (final source in [a.tasksByDate, b.tasksByDate]) {
      for (final entry in source.entries) {
        final dayTasks = tasksByDate.putIfAbsent(entry.key, () => []);
        for (final task in entry.value) {
          Task? existing;
          for (final candidate in dayTasks) {
            if (candidate.name == task.name) {
              existing = candidate;
              break;
            }
          }
          if (existing == null) {
            dayTasks.add(Task(name: task.name, isCompleted: task.isCompleted));
          } else if (task.isCompleted) {
            existing.isCompleted = true;
          }
        }
      }
    }

    return StudySnapshot(
      tests: tests,
      tasksByDate: tasksByDate,
      decks: decksByName.values.toList(),
      sessions: sessions,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'tests': [for (final test in tests) test.toJson()],
        'tasksByDate': [
          for (final entry in tasksByDate.entries)
            {
              'date': entry.key.toIso8601String(),
              'tasks': [for (final task in entry.value) task.toJson()],
            },
        ],
        'decks': [for (final deck in decks) deck.toJson()],
        'sessions': [for (final session in sessions) session.toJson()],
      };

  factory StudySnapshot.fromJson(Map<String, dynamic> json) {
    final tasksByDate = <DateTime, List<Task>>{};
    for (final raw in (json['tasksByDate'] as List? ?? const [])) {
      if (raw is! Map<String, dynamic>) continue;
      final date = DateTime.tryParse(raw['date']?.toString() ?? '');
      if (date == null) continue;
      tasksByDate[date] = [
        for (final t in (raw['tasks'] as List? ?? const []))
          if (t is Map<String, dynamic>) Task.fromJson(t),
      ];
    }

    return StudySnapshot(
      schemaVersion:
          (json['schemaVersion'] as num?)?.toInt() ?? currentSchemaVersion,
      tests: [
        for (final t in (json['tests'] as List? ?? const []))
          if (t is Map<String, dynamic>) Test.fromJson(t),
      ],
      tasksByDate: tasksByDate,
      decks: [
        for (final d in (json['decks'] as List? ?? const []))
          if (d is Map<String, dynamic>) Deck.fromJson(d),
      ],
      sessions: [
        for (final s in (json['sessions'] as List? ?? const []))
          if (s is Map<String, dynamic>) StudySession.fromJson(s),
      ],
    );
  }
}
