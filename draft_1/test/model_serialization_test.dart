import 'package:draft_1/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Test serialization', () {
    test('round-trips through JSON', () {
      final test = Test(
        'Chemistry',
        DateTime(2026, 7, 1),
        TestType.finals,
        TestDifficulty.hard,
        72,
        95,
      );

      final restored = Test.fromJson(test.toJson());

      expect(restored.subject, 'Chemistry');
      expect(restored.testDate, DateTime(2026, 7, 1));
      expect(restored.testType, TestType.finals);
      expect(restored.testDifficulty, TestDifficulty.hard);
      expect(restored.currentGrade, 72);
      expect(restored.targetGrade, 95);
    });

    test('falls back to defaults on malformed input', () {
      final restored = Test.fromJson({'testType': 'nonsense'});
      expect(restored.subject, 'unspecified');
      expect(restored.testType, TestType.unit);
      expect(restored.testDifficulty, TestDifficulty.normal);
    });
  });

  test('Task round-trips through JSON', () {
    final task = Task(name: 'Review chapter 4', isCompleted: true);
    final restored = Task.fromJson(task.toJson());
    expect(restored.name, 'Review chapter 4');
    expect(restored.isCompleted, isTrue);
  });

  test('Deck (with cards) round-trips through JSON', () {
    final deck = Deck(name: 'Bio', tags: ['science', 'exam'], cards: [
      Flashcard(question: 'Q1', answer: 'A1', tags: ['cells']),
      Flashcard(question: 'Q2', answer: 'A2'),
    ]);

    final restored = Deck.fromJson(deck.toJson());

    expect(restored.name, 'Bio');
    expect(restored.tags, ['science', 'exam']);
    expect(restored.cards.length, 2);
    expect(restored.cards.first.question, 'Q1');
    expect(restored.cards.first.tags, ['cells']);
    expect(restored.cards.last.answer, 'A2');
    expect(restored.cards.last.tags, isEmpty);
  });

  test('tags default to empty and survive missing/old payloads', () {
    // Payload with no `tags` key (an AI-generated or pre-tags card).
    final card = Flashcard.fromJson({'question': 'Q', 'answer': 'A'});
    expect(card.tags, isEmpty);

    final deck = Deck.fromJson({'name': 'Old'});
    expect(deck.tags, isEmpty);
  });

  test('parseTags trims, drops empties and dedupes case-insensitively', () {
    expect(
      parseTags(['  Math ', 'math', '', 'Science', 'MATH']),
      ['Math', 'Science'],
    );
    expect(parseTags('not a list'), isEmpty);
    expect(parseTags(null), isEmpty);
  });

  test('StudySession round-trips through JSON', () {
    final session = StudySession(
      date: DateTime(2026, 6, 28),
      subject: 'History',
      durationMinutes: 30,
      cardsReviewed: 20,
      correctAnswers: 18,
    );

    final restored = StudySession.fromJson(session.toJson());

    expect(restored.date, DateTime(2026, 6, 28));
    expect(restored.subject, 'History');
    expect(restored.durationMinutes, 30);
    expect(restored.cardsReviewed, 20);
    expect(restored.correctAnswers, 18);
  });
}
