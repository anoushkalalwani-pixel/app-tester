import 'package:draft_1/model.dart';
import 'package:draft_1/search/flashcard_search.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a small, fixed library of decks used across the search tests.
List<Deck> sampleDecks() => [
      Deck(
        name: 'Biology',
        tags: ['science', 'exam'],
        cards: [
          Flashcard(
            question: 'What is the powerhouse of the cell?',
            answer: 'The mitochondria',
            tags: ['cells'],
          ),
          Flashcard(question: 'What is osmosis?', answer: 'Water diffusion'),
        ],
      ),
      Deck(
        name: 'Spanish Vocab',
        tags: ['language'],
        cards: [
          Flashcard(question: 'Hello', answer: 'Hola'),
        ],
      ),
      Deck(name: 'Empty'),
    ];

void main() {
  group('searchFlashcards', () {
    test('empty query returns everything in scope', () {
      final results = searchFlashcards(sampleDecks());
      expect(results.decks.length, 3);
      expect(results.cards.length, 3);
    });

    test('keyword matches deck names and card text, case-insensitively', () {
      final results = searchFlashcards(sampleDecks(), query: 'MITOCHONDRIA');
      expect(results.decks, isEmpty);
      expect(results.cards.length, 1);
      expect(results.cards.single.deck.name, 'Biology');
    });

    test('keyword matches a deck by name', () {
      final results = searchFlashcards(sampleDecks(), query: 'spanish');
      expect(results.decks.single.name, 'Spanish Vocab');
      // The deck's single card also matches via its parent deck name.
      expect(results.cards.single.card.answer, 'Hola');
    });

    test('multiple terms must all match (AND)', () {
      final results = searchFlashcards(sampleDecks(), query: 'water osmosis');
      expect(results.cards.length, 1);
      expect(results.cards.single.card.question, 'What is osmosis?');
    });

    test('scope can restrict results to decks or cards only', () {
      final decksOnly =
          searchFlashcards(sampleDecks(), scope: SearchScope.decks);
      expect(decksOnly.cards, isEmpty);
      expect(decksOnly.decks.length, 3);

      final cardsOnly =
          searchFlashcards(sampleDecks(), scope: SearchScope.cards);
      expect(cardsOnly.decks, isEmpty);
      expect(cardsOnly.cards.length, 3);
    });

    test('tag filter requires all selected tags (AND)', () {
      final results =
          searchFlashcards(sampleDecks(), tags: {'science', 'exam'});
      expect(results.decks.single.name, 'Biology');
      // Both Biology cards inherit the deck-level science+exam tags.
      expect(results.cards.length, 2);
    });

    test('a deck-level tag also surfaces its cards', () {
      final results = searchFlashcards(sampleDecks(), tags: {'language'});
      expect(results.decks.single.name, 'Spanish Vocab');
      expect(results.cards.single.card.answer, 'Hola');
    });

    test('tag filtering is case-insensitive', () {
      final results = searchFlashcards(sampleDecks(), tags: {'SCIENCE'});
      expect(results.decks.single.name, 'Biology');
    });

    test('query and tags combine', () {
      final results = searchFlashcards(
        sampleDecks(),
        query: 'osmosis',
        tags: {'science'},
      );
      expect(results.cards.length, 1);
      expect(results.cards.single.card.question, 'What is osmosis?');
    });

    test('no matches yields an empty result', () {
      final results = searchFlashcards(sampleDecks(), query: 'zzz');
      expect(results.isEmpty, isTrue);
    });
  });

  group('allTags', () {
    test('collects distinct deck and card tags, sorted', () {
      expect(
        allTags(sampleDecks()),
        ['cells', 'exam', 'language', 'science'],
      );
    });

    test('dedupes case-insensitively, keeping first casing', () {
      final decks = [
        Deck(name: 'A', tags: ['Math']),
        Deck(name: 'B', tags: ['math', 'MATH']),
      ];
      expect(allTags(decks), ['Math']);
    });
  });
}
