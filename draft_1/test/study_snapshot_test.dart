import 'package:draft_1/globals.dart' as globals;
import 'package:draft_1/model.dart';
import 'package:draft_1/study_analytics.dart';
import 'package:draft_1/sync/study_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StudySnapshot sampleSnapshot() => StudySnapshot(
        tests: [Test('Math', DateTime(2026, 7, 1), TestType.quiz,
            TestDifficulty.easy, 80, 90)],
        tasksByDate: {
          DateTime(2026, 6, 29): [Task(name: 'Practice problems')],
        },
        decks: [
          Deck(name: 'Algebra', cards: [Flashcard(question: 'q', answer: 'a')]),
        ],
        sessions: [
          StudySession(
            date: DateTime(2026, 6, 28),
            subject: 'Math',
            durationMinutes: 20,
            cardsReviewed: 10,
            correctAnswers: 9,
          ),
        ],
      );

  test('round-trips a full snapshot through JSON', () {
    final restored = StudySnapshot.fromJson(sampleSnapshot().toJson());

    expect(restored.tests.single.subject, 'Math');
    expect(restored.tasksByDate[DateTime(2026, 6, 29)]!.single.name,
        'Practice problems');
    expect(restored.decks.single.name, 'Algebra');
    expect(restored.decks.single.cards.single.question, 'q');
    expect(restored.sessions.single.subject, 'Math');
  });

  test('capture() reads, and restore() writes, the global stores', () {
    globals.tests = [];
    globals.tasksByDate = {};
    globals.decks = [];
    StudyAnalytics.instance.replaceSessions([]);

    sampleSnapshot().restore();

    expect(globals.tests.single.subject, 'Math');
    expect(globals.decks.single.name, 'Algebra');
    expect(StudyAnalytics.instance.sessions.single.subject, 'Math');

    final captured = StudySnapshot.capture();
    expect(captured.tests.single.subject, 'Math');
    expect(captured.sessions.single.durationMinutes, 20);
  });

  group('merge', () {
    test('unions tests and drops exact duplicates', () {
      final shared =
          Test('Math', DateTime(2026, 7, 1), TestType.quiz, TestDifficulty.easy, 80, 90);
      final a = StudySnapshot(
        tests: [Test.fromJson(shared.toJson())],
        tasksByDate: {},
        decks: [],
        sessions: [],
      );
      final b = StudySnapshot(
        tests: [
          Test.fromJson(shared.toJson()), // duplicate -> dropped
          Test('Bio', DateTime(2026, 8, 1), TestType.unit, TestDifficulty.normal, 50, 100),
        ],
        tasksByDate: {},
        decks: [],
        sessions: [],
      );

      final merged = StudySnapshot.merge(a, b);
      expect(merged.tests.length, 2);
      expect(merged.tests.map((t) => t.subject), containsAll(['Math', 'Bio']));
    });

    test('merges decks by name and unions their cards', () {
      final a = StudySnapshot(
        tests: [],
        tasksByDate: {},
        decks: [
          Deck(name: 'Bio', cards: [Flashcard(question: 'q1', answer: 'a1')]),
        ],
        sessions: [],
      );
      final b = StudySnapshot(
        tests: [],
        tasksByDate: {},
        decks: [
          Deck(name: 'Bio', cards: [
            Flashcard(question: 'q1', answer: 'a1'), // dup
            Flashcard(question: 'q2', answer: 'a2'),
          ]),
          Deck(name: 'Chem'),
        ],
        sessions: [],
      );

      final merged = StudySnapshot.merge(a, b);
      expect(merged.decks.map((d) => d.name), containsAll(['Bio', 'Chem']));
      final bio = merged.decks.firstWhere((d) => d.name == 'Bio');
      expect(bio.cards.length, 2);
    });

    test('ORs task completion across copies for the same day/name', () {
      final day = DateTime(2026, 6, 29);
      final a = StudySnapshot(
        tests: [],
        tasksByDate: {
          day: [Task(name: 'Read', isCompleted: false)],
        },
        decks: [],
        sessions: [],
      );
      final b = StudySnapshot(
        tests: [],
        tasksByDate: {
          day: [Task(name: 'Read', isCompleted: true)],
        },
        decks: [],
        sessions: [],
      );

      final merged = StudySnapshot.merge(a, b);
      expect(merged.tasksByDate[day]!.length, 1);
      expect(merged.tasksByDate[day]!.single.isCompleted, isTrue);
    });
  });
}
